//
//  AskJuntoViewModel.swift
//  junto
//
//  Drives the Ask Junto conversation. Owns the thread lifecycle (create →
//  subscribe → run), the live message feed, and the side caches the render
//  rows need (person profiles, events, connection state).
//
//  Send flow: first message of a new conversation creates a thread, then runs
//  the agent. The backend inserts the user message + a pending assistant row
//  immediately and fills the placeholder when done — we just observe the
//  `getMessages` subscription and render reactively.
//

import SwiftUI
import Combine

/// What the agent is fetching, inferred from its live step — lets the card
/// skeletons show while it's still working, before the message completes.
enum AskJuntoBlockHint {
    case people
    case events
}

@MainActor
final class AskJuntoViewModel: ObservableObject {
    // MARK: - Published state

    @Published var messages: [AskJuntoMessageResponse] = []
    @Published var draft: String = ""
    @Published private(set) var threadId: String?

    /// True from the moment a message is sent until its assistant reply settles —
    /// drives the input-field loading state (no separate chat spinner).
    @Published private(set) var isSending = false

    /// Client-only user bubble shown instantly on send, before the server echoes
    /// it back over the subscription (kills the "message takes a second" lag).
    @Published private(set) var optimisticUser: AskJuntoMessageResponse?

    /// The assistant message currently streaming — only it types its text out;
    /// every other (history) message renders instantly.
    @Published private(set) var liveAssistantId: String?

    /// Inferred from the live step so card skeletons appear while the agent is
    /// still fetching — nil once the message completes (real cards take over).
    @Published private(set) var pendingBlockHint: AskJuntoBlockHint?

    /// Profiles + events referenced by content blocks, fetched on demand.
    @Published var userProfiles: [String: UserResponse] = [:]
    @Published var events: [String: EventWithRsvpResponse] = [:]

    /// Connection state for the person-card connect badge.
    @Published var connectedUserIds: Set<String> = []
    @Published var pendingConnectionIds: Set<String> = []

    var currentUserId: String?

    /// Server messages plus the optimistic user bubble (until the server echoes it).
    var displayMessages: [AskJuntoMessageResponse] {
        guard let optimisticUser else { return messages }
        return messages + [optimisticUser]
    }

    /// True once a conversation has started (so the empty state gives way).
    var hasConversation: Bool { threadId != nil && !messages.isEmpty }

    /// The in-flight assistant placeholder, if any.
    private var pendingAssistant: AskJuntoMessageResponse? {
        messages.last(where: { $0.isAssistant && $0.messageStatus == .pending })
    }

    /// Whether the agent is currently working (input field shows the loader).
    var isThinking: Bool { isSending || pendingAssistant != nil }

    /// The live step label to show while thinking ("Searching campus..." etc.).
    var thinkingStep: String {
        pendingAssistant?.step ?? "Thinking..."
    }

    // MARK: - Private

    private let convex = ConvexClientManager.shared
    private var messagesCancellable: AnyCancellable?
    private var eventCancellables: [String: AnyCancellable] = [:]

    // MARK: - Lifecycle

    func bootstrap(userId: String) async {
        currentUserId = userId
        await loadConnections(userId: userId)
    }

    // MARK: - Send

    func send(_ raw: String) {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let userId = currentUserId else { return }

        // Clear the composer + show the user's bubble immediately; the real
        // rows arrive via the subscription within a beat. isSending drives the
        // input loader before the pending row lands.
        draft = ""
        isSending = true
        optimisticUser = .optimisticUser(
            text: text,
            threadId: threadId,
            createdAt: Date().timeIntervalSince1970 * 1000
        )

        Task {
            do {
                let tid: String
                if let existing = threadId {
                    tid = existing
                } else {
                    tid = try await convex.createAskJuntoThread(userId: userId, firstMessage: text)
                    threadId = tid
                    subscribeMessages(threadId: tid)
                }
                try await convex.runAskJunto(threadId: tid, message: text, currentUserId: userId)
            } catch {
                print("AskJuntoViewModel: send error: \(error)")
            }
        }
    }

    // MARK: - Threads

    /// Open a past conversation from the history sheet.
    func openThread(_ id: String) {
        guard id != threadId else { return }
        threadId = id
        messages = []
        optimisticUser = nil
        liveAssistantId = nil
        pendingBlockHint = nil
        isSending = false
        subscribeMessages(threadId: id)
    }

    /// Reset to the empty "Hey there" state for a fresh conversation.
    func startNewConversation() {
        messagesCancellable?.cancel()
        messagesCancellable = nil
        threadId = nil
        messages = []
        optimisticUser = nil
        liveAssistantId = nil
        pendingBlockHint = nil
        isSending = false
        draft = ""
    }

    private func subscribeMessages(threadId: String) {
        messagesCancellable = convex.subscribeAskJuntoMessages(threadId: threadId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("AskJuntoViewModel: messages subscription error: \(error)")
                    }
                },
                receiveValue: { [weak self] msgs in
                    guard let self else { return }
                    self.messages = msgs

                    // Drop the optimistic bubble once the server echoes that user message.
                    if let pending = self.optimisticUser,
                       msgs.contains(where: { $0.isUser && $0.text == pending.text }) {
                        self.optimisticUser = nil
                    }

                    // Mark the streaming assistant so only it types its text out,
                    // and infer the incoming block type from its step for skeletons.
                    if let live = msgs.last(where: { $0.isAssistant && $0.messageStatus == .pending }) {
                        self.liveAssistantId = live.id
                        if let step = live.step?.lowercased() {
                            if step.contains("people") {
                                self.pendingBlockHint = .people
                            } else if step.contains("opportunit") || step.contains("event") {
                                self.pendingBlockHint = .events
                            }
                        }
                    } else {
                        self.pendingBlockHint = nil
                    }

                    // Once the assistant row has landed (pending or settled), the
                    // live `step`/status drives the loader — drop the optimistic flag.
                    if msgs.last?.isAssistant == true {
                        self.isSending = false
                    }
                    self.hydrate(from: msgs)
                }
            )
    }

    // MARK: - Hydration (profiles + events referenced by blocks)

    private func hydrate(from msgs: [AskJuntoMessageResponse]) {
        for message in msgs where message.isAssistant {
            guard let show = message.parsedBlocks?.show else { continue }
            switch show {
            case .people(let userIds, _):
                for id in userIds where userProfiles[id] == nil { fetchProfile(id) }
            case .opportunities(let eventIds, _):
                for id in eventIds where events[id] == nil { fetchEvent(id) }
            case .draftIntro(let targetUserId, _):
                if userProfiles[targetUserId] == nil { fetchProfile(targetUserId) }
            case .draftAsk, .action, .unknown:
                break
            }
        }
    }

    private func fetchProfile(_ userId: String) {
        Task {
            guard userProfiles[userId] == nil else { return }
            do {
                if let user = try await convex.fetchUser(id: userId) {
                    userProfiles[userId] = user
                }
            } catch {
                print("AskJuntoViewModel: fetch profile \(userId) error: \(error)")
            }
        }
    }

    private func fetchEvent(_ eventId: String) {
        // Subscribe live (with userId so myStatus is populated) so the card's
        // "Going" badge updates the moment the user RSVPs, here or anywhere.
        guard eventCancellables[eventId] == nil else { return }
        eventCancellables[eventId] = convex.subscribeEvent(id: eventId, userId: currentUserId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] event in
                    if let event { self?.events[eventId] = event }
                }
            )
    }

    // MARK: - Generative-UI actions (intro / rsvp / post)

    /// Send the drafted intro as a direct message to the target. Returns success
    /// so the card can flip to a "Sent" state.
    func sendIntro(to userId: String, message: String) async -> Bool {
        let body = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let myUserId = currentUserId, !body.isEmpty, userId != myUserId else { return false }
        do {
            _ = try await convex.sendMessage(senderId: myUserId, recipientId: userId, content: body)
            return true
        } catch {
            print("AskJuntoViewModel: sendIntro error: \(error)")
            return false
        }
    }

    /// RSVP the current user "going" to an event. Returns success so the card
    /// can flip to "Going".
    func rsvp(eventId: String) async -> Bool {
        guard let myUserId = currentUserId else { return false }
        do {
            _ = try await convex.rsvpToEvent(eventId: eventId, userId: myUserId, status: "going")
            return true
        } catch {
            print("AskJuntoViewModel: rsvp error: \(error)")
            return false
        }
    }

    /// Post the drafted ask to the feed. Returns success for the "Posted" state.
    func postAsk(title: String, body: String) async -> Bool {
        let content = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let myUserId = currentUserId, !content.isEmpty else { return false }
        do {
            _ = try await convex.createPost(PostInput(content: content, category: .asking), authorId: myUserId)
            return true
        } catch {
            print("AskJuntoViewModel: postAsk error: \(error)")
            return false
        }
    }

    // MARK: - Connections

    func loadConnections(userId: String) async {
        do {
            let connections = try await convex.fetchConnections(userId: userId)
            connectedUserIds = Set(connections.map { $0._id })
            let pendingIds = try await convex.fetchPendingSentIds(userId: userId)
            pendingConnectionIds = Set(pendingIds)
        } catch {
            print("AskJuntoViewModel: load connections error: \(error)")
        }
    }

    func connectionStatus(for userId: String) -> ConnectionStatus {
        if connectedUserIds.contains(userId) { return .connected }
        if pendingConnectionIds.contains(userId) { return .pendingSent }
        return .none
    }

    func sendConnectionRequest(toUserId: String) {
        guard let myUserId = currentUserId, toUserId != myUserId else { return }
        pendingConnectionIds.insert(toUserId)
        Task {
            do {
                _ = try await convex.sendConnectionRequest(requesterId: myUserId, accepterId: toUserId)
                AnalyticsService.shared.track(.connectionSent(toUserId: toUserId, source: .search))
                await loadConnections(userId: myUserId)
            } catch {
                pendingConnectionIds.remove(toUserId)
                print("AskJuntoViewModel: send connection error: \(error)")
            }
        }
    }
}
