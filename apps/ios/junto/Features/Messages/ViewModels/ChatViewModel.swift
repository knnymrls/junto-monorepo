//
//  ChatViewModel.swift
//  mkrs-world
//
//  ViewModel for a single chat conversation
//

import Foundation
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [MessageResponse] = []
    @Published var messageText = ""
    @Published var isSending = false
    @Published var isOtherTyping = false
    @Published var isLoading = true
    @Published var isRequest = false
    @Published var isAccepting = false
    @Published var isDeclining = false

    private(set) var conversationId: String?
    let otherParticipant: UserResponse
    let currentUserId: String
    let initialIsRequest: Bool

    private var messagesCancellable: AnyCancellable?
    private var typingCancellable: AnyCancellable?
    private var typingTimer: Timer?
    private let convex = ConvexClientManager.shared

    init(conversationId: String?, otherParticipant: UserResponse, currentUserId: String, isRequest: Bool = false) {
        self.conversationId = conversationId
        self.otherParticipant = otherParticipant
        self.currentUserId = currentUserId
        self.initialIsRequest = isRequest
        self.isRequest = isRequest
    }

    func subscribe() {
        guard let conversationId else {
            isLoading = false
            return
        }

        messagesCancellable?.cancel()
        typingCancellable?.cancel()

        messagesCancellable = convex.subscribeMessages(conversationId: conversationId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Messages subscription error: \(error)")
                    }
                },
                receiveValue: { [weak self] messages in
                    self?.messages = messages
                    self?.isLoading = false
                }
            )

        typingCancellable = convex.subscribeTypingIndicator(conversationId: conversationId, userId: currentUserId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] isTyping in
                    self?.isOtherTyping = isTyping
                }
            )
    }

    func sendMessage(gifUrl: String? = nil) {
        let content = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty || gifUrl != nil else { return }

        isSending = true
        let messageContent = gifUrl != nil && content.isEmpty ? " " : content
        messageText = ""
        let wasNewConversation = conversationId == nil

        Task {
            do {
                _ = try await convex.sendMessage(
                    senderId: currentUserId,
                    recipientId: otherParticipant._id,
                    content: messageContent,
                    gifUrl: gifUrl
                )

                // First message created the conversation — look it up and subscribe
                if wasNewConversation {
                    let conv = try await convex.fetchConversationBetween(
                        userId1: currentUserId,
                        userId2: otherParticipant._id
                    )
                    if let conv {
                        conversationId = conv._id
                        subscribe()
                    }
                }

                AnalyticsService.shared.track(.messageSent(conversationId: conversationId ?? "new"))
            } catch {
                print("Send message error: \(error)")
                messageText = content
            }
            isSending = false
        }
    }

    func markAsRead() {
        guard let conversationId else { return }
        Task {
            try? await convex.markConversationRead(conversationId: conversationId, userId: currentUserId)
        }
    }

    func startTyping() {
        guard let conversationId else { return }

        typingTimer?.invalidate()
        Task {
            try? await convex.setTyping(conversationId: conversationId, userId: currentUserId)
        }

        typingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.stopTyping()
            }
        }
    }

    func stopTyping() {
        typingTimer?.invalidate()
        typingTimer = nil
        guard let conversationId else { return }
        Task {
            try? await convex.clearTyping(conversationId: conversationId, userId: currentUserId)
        }
    }

    func acceptRequest() {
        guard let conversationId else { return }
        isAccepting = true
        Task {
            do {
                try await convex.acceptMessageRequest(conversationId: conversationId, userId: currentUserId)
                isRequest = false
            } catch {
                print("Accept request error: \(error)")
            }
            isAccepting = false
        }
    }

    func declineRequest(dismiss: @escaping () -> Void) {
        guard let conversationId else { return }
        isDeclining = true
        Task {
            do {
                try await convex.declineMessageRequest(conversationId: conversationId, userId: currentUserId)
                dismiss()
            } catch {
                print("Decline request error: \(error)")
            }
            isDeclining = false
        }
    }

    deinit {
        messagesCancellable?.cancel()
        typingCancellable?.cancel()
        typingTimer?.invalidate()
    }
}
