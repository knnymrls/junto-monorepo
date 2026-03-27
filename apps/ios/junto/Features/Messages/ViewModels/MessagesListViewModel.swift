//
//  MessagesListViewModel.swift
//  mkrs-world
//
//  ViewModel for the messages/conversations list
//

import Foundation
import Combine

enum MessagesFilter: String, CaseIterable {
    case inbox = "Inbox"
    case requests = "Requests"
}

@MainActor
class MessagesListViewModel: ObservableObject {
    @Published var conversations: [ConversationResponse] = []
    @Published var connections: [UserResponse] = []
    @Published var isLoading = true
    @Published var searchText = ""
    @Published var filter: MessagesFilter = .inbox
    @Published var dismissedSuggestionIds: Set<String> = []

    private var conversationsCancellable: AnyCancellable?
    private var connectionsCancellable: AnyCancellable?
    private let convex = ConvexClientManager.shared

    /// Active conversations (not incoming requests)
    var inboxConversations: [ConversationResponse] {
        conversations.filter { conv in
            let status = conv.status ?? "active"
            return status == "active" || (conv.isSentRequest == true)
        }
    }

    /// Incoming message requests (requests TO this user)
    var requestConversations: [ConversationResponse] {
        conversations.filter { $0.isRequest == true }
    }

    /// Number of pending requests (for badge)
    var requestCount: Int {
        requestConversations.count
    }

    /// Conversations filtered by current tab + search text
    var filteredConversations: [ConversationResponse] {
        let base = filter == .inbox ? inboxConversations : requestConversations
        if searchText.isEmpty { return base }
        let query = searchText.lowercased()
        return base.filter { conv in
            conv.otherParticipant?.name.lowercased().contains(query) == true ||
            conv.lastMessagePreview?.lowercased().contains(query) == true
        }
    }

    /// Connections who don't have an existing conversation yet (and aren't dismissed)
    var suggestedUsers: [UserResponse] {
        guard filter == .inbox else { return [] }
        let conversationParticipantIds = Set(conversations.compactMap { $0.otherParticipant?._id })
        let suggested = connections.filter { user in
            !conversationParticipantIds.contains(user._id) &&
            !dismissedSuggestionIds.contains(user._id)
        }
        if searchText.isEmpty { return suggested }
        let query = searchText.lowercased()
        return suggested.filter { $0.name.lowercased().contains(query) }
    }

    func subscribe(userId: String) {
        conversationsCancellable = convex.subscribeConversations(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Messages subscription error: \(error)")
                    }
                },
                receiveValue: { [weak self] conversations in
                    self?.conversations = conversations
                    self?.isLoading = false
                }
            )

        connectionsCancellable = convex.subscribeConnections(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] connections in
                    self?.connections = connections
                }
            )
    }

    func dismissSuggestion(_ userId: String) {
        dismissedSuggestionIds.insert(userId)
    }

    deinit {
        conversationsCancellable?.cancel()
        connectionsCancellable?.cancel()
    }
}
