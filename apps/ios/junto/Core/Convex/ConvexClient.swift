//
//  ConvexClient.swift
//  mkrs-world
//
//  Convex client singleton for backend communication
//

import Foundation
import ConvexMobile
import Combine
import UIKit

@MainActor
class ConvexClientManager: ObservableObject {
    static let shared = ConvexClientManager()

    let client: ConvexClient

    private init() {
        client = ConvexClient(deploymentUrl: "https://avid-chicken-478.convex.cloud")
    }
}

// MARK: - Subscriptions (Real-time queries)

extension ConvexClientManager {

    // MARK: Users

    /// Subscribe to users list with real-time updates
    func subscribeUsers(universityId: String? = nil, limit: Int? = nil) -> AnyPublisher<[UserResponse], ClientError> {
        var args: [String: (any ConvexEncodable)?] = [:]
        if let universityId = universityId {
            args["universityId"] = universityId
        }
        if let limit = limit {
            args["limit"] = Double(limit)
        }

        if args.isEmpty {
            return client.subscribe(to: "users:list", yielding: [UserResponse].self)
        } else {
            return client.subscribe(to: "users:list", with: args, yielding: [UserResponse].self)
        }
    }

    /// Subscribe to a single user by ID
    func subscribeUser(id: String) -> AnyPublisher<UserResponse?, ClientError> {
        return client.subscribe(to: "users:get", with: ["id": id], yielding: UserResponse?.self)
    }

    /// Subscribe to user by Clerk ID
    func subscribeUserByClerkId(clerkId: String) -> AnyPublisher<UserResponse?, ClientError> {
        return client.subscribe(to: "users:getByClerkId", with: ["clerkId": clerkId], yielding: UserResponse?.self)
    }

    // MARK: Connections

    /// Subscribe to connections for a user
    func subscribeConnections(userId: String) -> AnyPublisher<[UserResponse], ClientError> {
        return client.subscribe(to: "connections:listForUser", with: ["userId": userId], yielding: [UserResponse].self)
    }

    // MARK: Suggested Matches

    /// Fetch today's pre-computed daily matches (query, not action — instant)
    func fetchSuggestedMatchesQuery(userId: String) async throws -> [SuggestedMatchResponse] {
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = client.subscribe(to: "dailyMatches:getDailyMatches", with: ["userId": userId], yielding: [SuggestedMatchResponse].self)
                .first()
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { matches in
                        continuation.resume(returning: matches)
                    }
                )
        }
    }

    /// Trigger on-demand match generation for a user (first-open fallback)
    func generateDailyMatchesAction(userId: String) async throws {
        let _: String? = try await client.action("dailyMatches:generateForCurrentUser", with: ["userId": userId])
    }

    // MARK: Search

    /// Quick search — fast name + vector search, no AI
    func quickSearch(query: String, currentUserId: String) async throws -> QuickSearchResponse {
        let args: [String: (any ConvexEncodable)?] = [
            "query": query,
            "currentUserId": currentUserId
        ]
        return try await client.action("search:quickSearch", with: args)
    }

    /// AI search — full LLM-powered search with reasoning
    func searchPeople(query: String, currentUserId: String) async throws -> AISearchResponse {
        let args: [String: (any ConvexEncodable)?] = [
            "query": query,
            "currentUserId": currentUserId
        ]
        return try await client.action("search:searchPeople", with: args)
    }

    /// Vector search — fast retrieval with auto-explanations, no LLM
    func vectorSearch(query: String, currentUserId: String) async throws -> VectorSearchResponse {
        let args: [String: (any ConvexEncodable)?] = [
            "query": query,
            "currentUserId": currentUserId
        ]
        return try await client.action("search:vectorSearch", with: args)
    }

    /// LLM enhancement — takes user IDs from vector search and adds AI reasoning
    func enhanceWithLLM(query: String, userIds: [String], currentUserId: String) async throws -> AISearchResponse {
        let userIdsEncodable: [ConvexEncodable?] = userIds.map { $0 as ConvexEncodable? }
        let args: [String: (any ConvexEncodable)?] = [
            "query": query,
            "userIds": userIdsEncodable,
            "currentUserId": currentUserId
        ]
        return try await client.action("search:enhanceWithLLM", with: args)
    }

    /// Name autocomplete — lightweight name search for autocomplete
    func nameAutocomplete(query: String, currentUserId: String) async throws -> [NameAutocompleteResult] {
        let args: [String: (any ConvexEncodable)?] = [
            "query": query,
            "currentUserId": currentUserId
        ]
        return try await client.action("users:searchByName", with: args)
    }

    // MARK: Search Sessions (Streaming)

    /// Create a search session — returns session ID
    func createSearchSession(query: String, currentUserId: String) async throws -> String {
        return try await client.mutation("searchSessions:createSession", with: [
            "userId": currentUserId,
            "query": query
        ])
    }

    /// Subscribe to search session for real-time streaming updates
    func subscribeSearchSession(sessionId: String) -> AnyPublisher<SearchSessionResponse?, ClientError> {
        return client.subscribe(to: "searchSessions:getSession", with: ["sessionId": sessionId], yielding: SearchSessionResponse?.self)
    }

    /// Fire the streaming LLM enhancement action (returns when complete)
    func streamEnhanceWithLLM(sessionId: String, query: String, userIds: [String], currentUserId: String) async throws {
        let userIdsEncodable: [ConvexEncodable?] = userIds.map { $0 as ConvexEncodable? }
        let args: [String: (any ConvexEncodable)?] = [
            "sessionId": sessionId,
            "query": query,
            "userIds": userIdsEncodable,
            "currentUserId": currentUserId
        ]
        let _: String? = try await client.action("search:streamEnhanceWithLLM", with: args)
    }

    // MARK: Search Chats

    /// Subscribe to search chat list for a user
    func subscribeSearchChats(userId: String) -> AnyPublisher<[SearchChatResponse], ClientError> {
        return client.subscribe(to: "searchChats:listChats", with: ["userId": userId], yielding: [SearchChatResponse].self)
    }

    /// Subscribe to messages for a search chat
    func subscribeSearchMessages(chatId: String) -> AnyPublisher<[SearchMessageResponse], ClientError> {
        return client.subscribe(to: "searchChats:getMessages", with: ["chatId": chatId], yielding: [SearchMessageResponse].self)
    }

    /// Delete a search chat
    func deleteSearchChat(chatId: String) async throws {
        let _: String? = try await client.mutation("searchChats:deleteChat", with: ["chatId": chatId])
    }

    // MARK: Posts

    /// Subscribe to feed for a user (connections first, then recent)
    func subscribeFeed(userId: String, limit: Int? = nil, offset: Int? = nil) -> AnyPublisher<[PostResponse], ClientError> {
        var args: [String: (any ConvexEncodable)?] = ["userId": userId]
        if let limit = limit {
            args["limit"] = Double(limit)
        }
        if let offset = offset {
            args["offset"] = Double(offset)
        }
        return client.subscribe(to: "posts:getFeed", with: args, yielding: [PostResponse].self)
    }

    /// Subscribe to posts list
    func subscribePosts(authorId: String? = nil, limit: Int? = nil) -> AnyPublisher<[PostResponse], ClientError> {
        var args: [String: (any ConvexEncodable)?] = [:]
        if let authorId = authorId {
            args["authorId"] = authorId
        }
        if let limit = limit {
            args["limit"] = Double(limit)
        }

        if args.isEmpty {
            return client.subscribe(to: "posts:list", yielding: [PostResponse].self)
        } else {
            return client.subscribe(to: "posts:list", with: args, yielding: [PostResponse].self)
        }
    }

    /// Subscribe to a single post
    func subscribePost(postId: String) -> AnyPublisher<PostResponse?, ClientError> {
        return client.subscribe(to: "posts:get", with: ["postId": postId], yielding: PostResponse?.self)
    }

    /// Subscribe to posts by author
    func subscribePostsByAuthor(authorId: String, limit: Int? = nil) -> AnyPublisher<[PostResponse], ClientError> {
        var args: [String: (any ConvexEncodable)?] = ["authorId": authorId]
        if let limit = limit {
            args["limit"] = Double(limit)
        }
        return client.subscribe(to: "posts:getByAuthor", with: args, yielding: [PostResponse].self)
    }

    // MARK: Comments

    /// Subscribe to comments for a post
    func subscribeComments(postId: String, limit: Int? = nil) -> AnyPublisher<[CommentResponse], ClientError> {
        var args: [String: (any ConvexEncodable)?] = ["postId": postId]
        if let limit = limit {
            args["limit"] = Double(limit)
        }
        return client.subscribe(to: "comments:listByPost", with: args, yielding: [CommentResponse].self)
    }

    // MARK: Events

    /// Subscribe to upcoming events
    func subscribeUpcomingEvents(universityId: String? = nil, limit: Int? = nil) -> AnyPublisher<[EventResponse], ClientError> {
        var args: [String: (any ConvexEncodable)?] = [:]
        if let universityId = universityId {
            args["universityId"] = universityId
        }
        if let limit = limit {
            args["limit"] = Double(limit)
        }

        if args.isEmpty {
            return client.subscribe(to: "events:listUpcoming", yielding: [EventResponse].self)
        } else {
            return client.subscribe(to: "events:listUpcoming", with: args, yielding: [EventResponse].self)
        }
    }

    /// Subscribe to a single event with RSVP counts
    func subscribeEvent(id: String) -> AnyPublisher<EventWithRsvpResponse?, ClientError> {
        return client.subscribe(to: "events:get", with: ["id": id], yielding: EventWithRsvpResponse?.self)
    }

    /// Subscribe to event attendees
    func subscribeEventAttendees(eventId: String) -> AnyPublisher<[EventAttendee], ClientError> {
        return client.subscribe(to: "events:getAttendees", with: ["eventId": eventId], yielding: [EventAttendee].self)
    }

    /// Get user's RSVP status for an event
    func subscribeUserRsvp(eventId: String, userId: String) -> AnyPublisher<EventRsvpResponse?, ClientError> {
        return client.subscribe(to: "events:getUserRsvp", with: [
            "eventId": eventId,
            "userId": userId
        ], yielding: EventRsvpResponse?.self)
    }

    /// Subscribe to events needing feedback (ended events user attended but hasn't reviewed)
    func subscribeEventsNeedingFeedback(userId: String) -> AnyPublisher<[EventWithRsvpResponse], ClientError> {
        return client.subscribe(to: "events:getEventsNeedingFeedback", with: [
            "userId": userId
        ], yielding: [EventWithRsvpResponse].self)
    }

    // MARK: Messages

    /// Subscribe to conversations for a user
    func subscribeConversations(userId: String) -> AnyPublisher<[ConversationResponse], ClientError> {
        return client.subscribe(to: "messages:listConversations", with: ["userId": userId], yielding: [ConversationResponse].self)
    }

    /// Subscribe to messages for a conversation
    func subscribeMessages(conversationId: String, limit: Int? = nil) -> AnyPublisher<[MessageResponse], ClientError> {
        var args: [String: (any ConvexEncodable)?] = ["conversationId": conversationId]
        if let limit { args["limit"] = Double(limit) }
        return client.subscribe(to: "messages:getMessages", with: args, yielding: [MessageResponse].self)
    }

    /// Subscribe to total unread message count (for tab badge)
    func subscribeUnreadMessageCount(userId: String) -> AnyPublisher<Int, ClientError> {
        return client.subscribe(to: "messages:getUnreadMessageCount", with: ["userId": userId], yielding: Int.self)
    }

    /// Subscribe to typing indicator for a conversation
    func subscribeTypingIndicator(conversationId: String, userId: String) -> AnyPublisher<Bool, ClientError> {
        return client.subscribe(to: "messages:getTypingIndicator", with: [
            "conversationId": conversationId,
            "userId": userId
        ], yielding: Bool.self)
    }

    // MARK: Portfolio

    /// Subscribe to portfolio items for a user
    func subscribePortfolioItems(userId: String) -> AnyPublisher<[PortfolioItemResponse], ClientError> {
        return client.subscribe(to: "portfolio:list", with: ["userId": userId], yielding: [PortfolioItemResponse].self)
    }

    // MARK: Notifications

    /// Subscribe to notifications for a user
    func subscribeNotifications(userId: String, limit: Int? = nil) -> AnyPublisher<[NotificationResponse], ClientError> {
        var args: [String: (any ConvexEncodable)?] = ["userId": userId]
        if let limit { args["limit"] = Double(limit) }
        return client.subscribe(to: "notifications:listForUser", with: args, yielding: [NotificationResponse].self)
    }

    /// Subscribe to unread notification count
    func subscribeUnreadCount(userId: String) -> AnyPublisher<Int, ClientError> {
        return client.subscribe(to: "notifications:getUnreadCount", with: ["userId": userId], yielding: Int.self)
    }
}

// MARK: - File Storage

extension ConvexClientManager {

    /// Generate an upload URL for file storage
    func generateUploadUrl() async throws -> String {
        return try await client.mutation("storage:generateUploadUrl", with: [:] as [String: String])
    }

    /// Compress image data while preserving quality (default 1MB max)
    /// Returns compressed JPEG data
    private func compressImage(_ imageData: Data, maxSizeKB: Int = 1024) -> Data? {
        guard let image = UIImage(data: imageData) else { return nil }
        return compressUIImage(image, maxSizeKB: maxSizeKB)
    }

    /// Compress UIImage while preserving quality (default 1MB max)
    /// Returns compressed JPEG data
    private func compressUIImage(_ image: UIImage, maxSizeKB: Int = 1024) -> Data? {
        let maxBytes = maxSizeKB * 1024

        // First, resize if image is very large (> 3000px on longest side)
        var processedImage = image
        let maxDimension: CGFloat = 3000
        if image.size.width > maxDimension || image.size.height > maxDimension {
            let scale = maxDimension / max(image.size.width, image.size.height)
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            if let resized = UIGraphicsGetImageFromCurrentImageContext() {
                processedImage = resized
            }
            UIGraphicsEndImageContext()
        }

        // Start with high quality and reduce gradually if needed
        var compression: CGFloat = 0.9
        var imageData = processedImage.jpegData(compressionQuality: compression)

        while let data = imageData, data.count > maxBytes, compression > 0.5 {
            compression -= 0.05
            imageData = processedImage.jpegData(compressionQuality: compression)
        }

        // If still too large after quality reduction, resize proportionally
        if let data = imageData, data.count > maxBytes {
            let scale: CGFloat = 0.8
            let newSize = CGSize(
                width: processedImage.size.width * scale,
                height: processedImage.size.height * scale
            )
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            processedImage.draw(in: CGRect(origin: .zero, size: newSize))
            if let smaller = UIGraphicsGetImageFromCurrentImageContext() {
                imageData = smaller.jpegData(compressionQuality: 0.85)
            }
            UIGraphicsEndImageContext()
        }

        return imageData
    }

    /// Upload image data with automatic compression and return the storage ID
    /// Images are compressed to ~200KB before upload to reduce bandwidth
    func uploadImage(_ imageData: Data) async throws -> String {
        // Compress the image before uploading
        guard let compressedData = compressImage(imageData) else {
            throw ConvexUploadError.compressionFailed
        }

        let originalKB = imageData.count / 1024
        let compressedKB = compressedData.count / 1024
        print("ConvexClient: Compressed image from \(originalKB)KB to \(compressedKB)KB")

        return try await uploadRawData(compressedData, contentType: "image/jpeg")
    }

    /// Upload a UIImage with automatic compression and return the storage ID
    func uploadImage(_ image: UIImage) async throws -> String {
        guard let compressedData = compressUIImage(image) else {
            throw ConvexUploadError.compressionFailed
        }

        let compressedKB = compressedData.count / 1024
        print("ConvexClient: Compressed image to \(compressedKB)KB")

        return try await uploadRawData(compressedData, contentType: "image/jpeg")
    }

    /// Upload raw data without compression (for pre-compressed or non-image data)
    func uploadRawData(_ data: Data, contentType: String = "application/octet-stream") async throws -> String {
        // Get upload URL from Convex
        let uploadUrl = try await generateUploadUrl()

        guard let url = URL(string: uploadUrl) else {
            throw ConvexUploadError.invalidUrl
        }

        // Upload the data
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        let (responseData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ConvexUploadError.uploadFailed
        }

        // Parse the storage ID from response
        let json = try JSONDecoder().decode(UploadResponse.self, from: responseData)
        return json.storageId
    }

    /// Get a URL for a stored file
    func getFileUrl(storageId: String) async throws -> String? {
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = client.subscribe(to: "storage:getUrl", with: ["storageId": storageId], yielding: String?.self)
                .first()
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { url in
                        continuation.resume(returning: url)
                    }
                )
        }
    }
}

enum ConvexUploadError: Error, LocalizedError {
    case invalidUrl
    case uploadFailed
    case noStorageId
    case compressionFailed

    var errorDescription: String? {
        switch self {
        case .invalidUrl: return "Invalid upload URL"
        case .uploadFailed: return "Failed to upload image"
        case .noStorageId: return "No storage ID returned"
        case .compressionFailed: return "Failed to compress image"
        }
    }
}

struct UploadResponse: Codable {
    let storageId: String
}

// MARK: - Mutations (One-off writes)

extension ConvexClientManager {

    // MARK: Users

    /// Create or update a user profile
    func upsertUser(_ user: UserInput) async throws -> String {
        return try await client.mutation("users:upsert", with: user.toArgs())
    }

    // MARK: Connections

    /// Create a connection between two users (instant - for MVP)
    func connect(requesterId: String, accepterId: String) async throws -> String {
        return try await client.mutation("connections:connect", with: [
            "requesterId": requesterId,
            "accepterId": accepterId
        ])
    }

    /// Send a connection request (creates pending connection)
    func sendConnectionRequest(requesterId: String, accepterId: String) async throws -> String {
        return try await client.mutation("connections:sendRequest", with: [
            "requesterId": requesterId,
            "accepterId": accepterId
        ])
    }

    /// Accept a connection request
    func acceptConnectionRequest(connectionId: String) async throws -> String {
        return try await client.mutation("connections:acceptRequest", with: [
            "connectionId": connectionId
        ])
    }

    func rejectConnectionRequest(connectionId: String) async throws -> String {
        return try await client.mutation("connections:rejectRequest", with: [
            "connectionId": connectionId
        ])
    }

    func withdrawConnectionRequest(requesterId: String, accepterId: String) async throws -> String {
        return try await client.mutation("connections:withdrawRequest", with: [
            "requesterId": requesterId,
            "accepterId": accepterId
        ])
    }

    func removeConnection(userId1: String, userId2: String) async throws -> String {
        return try await client.mutation("connections:removeConnection", with: [
            "userId1": userId1,
            "userId2": userId2
        ])
    }

    func acceptConnectionRequestByUsers(currentUserId: String, otherUserId: String) async throws -> String {
        return try await client.mutation("connections:acceptRequestByUsers", with: [
            "currentUserId": currentUserId,
            "otherUserId": otherUserId
        ])
    }

    // MARK: Events

    /// RSVP to an event
    func rsvpToEvent(eventId: String, userId: String, status: String) async throws -> String {
        return try await client.mutation("events:rsvp", with: [
            "eventId": eventId,
            "userId": userId,
            "status": status
        ])
    }

    func markCalendarAdded(eventId: String, userId: String) async throws {
        let _: String? = try await client.mutation("events:markCalendarAdded", with: [
            "eventId": eventId,
            "userId": userId
        ])
    }

    // MARK: Event Feedback

    /// Submit feedback for an event
    func submitEventFeedback(eventId: String, userId: String, rating: Int, improvements: [String], wantToConnectWith: [String]) async throws -> String {
        let encodableImprovements: [ConvexEncodable?] = improvements.map { $0 as ConvexEncodable? }
        let encodableConnections: [ConvexEncodable?] = wantToConnectWith.map { $0 as ConvexEncodable? }
        return try await client.mutation("events:submitFeedback", with: [
            "eventId": eventId,
            "userId": userId,
            "rating": Double(rating),
            "improvements": encodableImprovements,
            "wantToConnectWith": encodableConnections
        ] as [String: (any ConvexEncodable)?])
    }

    // MARK: Posts

    /// Create a new post
    func createPost(_ input: PostInput, authorId: String) async throws -> String {
        return try await client.mutation("posts:create", with: input.toArgs(authorId: authorId))
    }

    /// Update a post
    func updatePost(postId: String, content: String? = nil, category: PostResponse.PostCategory? = nil, imageUrl: String? = nil, linkUrl: String? = nil) async throws -> String {
        var args: [String: (any ConvexEncodable)?] = ["postId": postId]
        if let content = content { args["content"] = content }
        if let category = category { args["category"] = category.rawValue }
        if let imageUrl = imageUrl { args["imageUrl"] = imageUrl }
        if let linkUrl = linkUrl { args["linkUrl"] = linkUrl }
        return try await client.mutation("posts:update", with: args)
    }

    /// Delete a post
    func deletePost(postId: String) async throws -> String {
        return try await client.mutation("posts:remove", with: ["postId": postId])
    }

    // MARK: Comments

    /// Create a comment on a post
    func createComment(_ input: CommentInput, authorId: String) async throws -> String {
        return try await client.mutation("comments:create", with: input.toArgs(authorId: authorId))
    }

    /// Delete a comment
    func deleteComment(commentId: String) async throws -> String {
        return try await client.mutation("comments:remove", with: ["commentId": commentId])
    }

    /// Update a comment
    func updateComment(commentId: String, content: String) async throws -> String {
        return try await client.mutation("comments:update", with: ["commentId": commentId, "content": content])
    }

    // MARK: Notifications

    func markNotificationRead(notificationId: String) async throws {
        let _: String? = try await client.mutation("notifications:markAsRead", with: ["notificationId": notificationId])
    }

    func markAllNotificationsRead(userId: String) async throws {
        let _: Int? = try await client.mutation("notifications:markAllAsRead", with: ["userId": userId])
    }

    func removeNotification(notificationId: String) async throws {
        let _: String? = try await client.mutation("notifications:remove", with: ["notificationId": notificationId])
    }

    func updateNotificationTitle(notificationId: String, title: String) async throws {
        let _: String? = try await client.mutation("notifications:updateTitle", with: [
            "notificationId": notificationId,
            "title": title
        ])
    }

    // MARK: Messages

    func sendMessage(senderId: String, recipientId: String, content: String, gifUrl: String? = nil) async throws -> String {
        var args: [String: (any ConvexEncodable)?] = [
            "senderId": senderId,
            "recipientId": recipientId,
            "content": content
        ]
        if let gifUrl { args["gifUrl"] = gifUrl }
        return try await client.mutation("messages:sendMessage", with: args)
    }

    func markConversationRead(conversationId: String, userId: String) async throws {
        let _: String? = try await client.mutation("messages:markConversationRead", with: [
            "conversationId": conversationId,
            "userId": userId
        ])
    }

    func setTyping(conversationId: String, userId: String) async throws {
        let _: String? = try await client.mutation("messages:setTyping", with: [
            "conversationId": conversationId,
            "userId": userId
        ])
    }

    func clearTyping(conversationId: String, userId: String) async throws {
        let _: String? = try await client.mutation("messages:clearTyping", with: [
            "conversationId": conversationId,
            "userId": userId
        ])
    }

    func acceptMessageRequest(conversationId: String, userId: String) async throws {
        let _: String? = try await client.mutation("messages:acceptMessageRequest", with: [
            "conversationId": conversationId,
            "userId": userId
        ])
    }

    func declineMessageRequest(conversationId: String, userId: String) async throws {
        let _: String? = try await client.mutation("messages:declineMessageRequest", with: [
            "conversationId": conversationId,
            "userId": userId
        ])
    }

    // MARK: Portfolio

    func createPortfolioItem(
        userId: String,
        type: String,
        title: String? = nil,
        url: String? = nil,
        description: String? = nil,
        imageUrls: [String]? = nil,
        organization: String? = nil,
        startDate: String? = nil,
        endDate: String? = nil,
        size: String? = nil
    ) async throws -> String {
        var args: [String: (any ConvexEncodable)?] = [
            "userId": userId,
            "type": type
        ]
        if let title { args["title"] = title }
        if let url { args["url"] = url }
        if let description { args["description"] = description }
        if let imageUrls, !imageUrls.isEmpty {
            let encodable: [ConvexEncodable?] = imageUrls.map { $0 as ConvexEncodable? }
            args["imageUrls"] = encodable
        }
        if let organization { args["organization"] = organization }
        if let startDate { args["startDate"] = startDate }
        if let endDate { args["endDate"] = endDate }
        if let size { args["size"] = size }
        return try await client.mutation("portfolio:create", with: args)
    }

    func deletePortfolioItem(id: String) async throws {
        let _: String? = try await client.mutation("portfolio:remove", with: ["id": id])
    }

    func updatePortfolioItem(
        id: String,
        title: String? = nil,
        url: String? = nil,
        description: String? = nil,
        size: String? = nil,
        order: Int? = nil
    ) async throws {
        var args: [String: (any ConvexEncodable)?] = ["id": id]
        if let title { args["title"] = title }
        if let url { args["url"] = url }
        if let description { args["description"] = description }
        if let size { args["size"] = size }
        if let order { args["order"] = Double(order) }
        let _: String? = try await client.mutation("portfolio:update", with: args)
    }

    func reorderPortfolioItems(items: [(id: String, order: Int, size: String?)]) async throws {
        let encodableItems: [ConvexEncodable?] = items.map { item in
            var dict: [String: (any ConvexEncodable)?] = [
                "id": item.id,
                "order": Double(item.order)
            ]
            if let size = item.size {
                dict["size"] = size
            }
            return dict as ConvexEncodable?
        }
        let _: String? = try await client.mutation("portfolio:reorder", with: ["items": encodableItems])
    }

    // MARK: Reports

    func reportPost(reporterId: String, postId: String, reason: String, details: String? = nil) async throws -> String {
        var args: [String: (any ConvexEncodable)?] = [
            "reporterId": reporterId,
            "postId": postId,
            "reason": reason
        ]
        if let details = details, !details.isEmpty {
            args["details"] = details
        }
        return try await client.mutation("reports:create", with: args)
    }

    // MARK: Device Tokens

    func registerDeviceToken(userId: String, token: String, appVersion: String?, deviceModel: String?, osVersion: String?) async throws {
        let _: String? = try await client.mutation("deviceTokens:register", with: [
            "userId": userId,
            "token": token,
            "platform": "ios",
            "appVersion": appVersion,
            "deviceModel": deviceModel,
            "osVersion": osVersion
        ] as [String: (any ConvexEncodable)?])
    }

    func removeDeviceToken(token: String) async throws {
        let _: Bool? = try await client.mutation("deviceTokens:remove", with: ["token": token])
    }
}

// MARK: - One-shot Queries (async convenience methods)

extension ConvexClientManager {

    /// Fetch users once (takes first value from subscription)
    func fetchUsers(universityId: String? = nil, limit: Int? = nil) async throws -> [UserResponse] {
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = subscribeUsers(universityId: universityId, limit: limit)
                .first()
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { users in
                        continuation.resume(returning: users)
                    }
                )
        }
    }

    /// Fetch a single user by ID once
    func fetchUser(id: String) async throws -> UserResponse? {
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = subscribeUser(id: id)
                .first()
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { user in
                        continuation.resume(returning: user)
                    }
                )
        }
    }

    /// Fetch user by Clerk ID once
    func fetchUserByClerkId(clerkId: String) async throws -> UserResponse? {
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = subscribeUserByClerkId(clerkId: clerkId)
                .first()
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { user in
                        continuation.resume(returning: user)
                    }
                )
        }
    }

    /// Fetch user by name (for mentions)
    func fetchUserByName(name: String) async throws -> UserResponse? {
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = client.subscribe(to: "users:getByName", with: ["name": name], yielding: UserResponse?.self)
                .first()
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { user in
                        continuation.resume(returning: user)
                    }
                )
        }
    }

    /// Fast name search for cards (typing phase — no embedding, no action overhead)
    func fetchNameSearchResults(query: String, currentUserId: String) async throws -> [UserResponse] {
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = client.subscribe(to: "users:searchForCards", with: [
                "query": query,
                "currentUserId": currentUserId,
                "limit": 8,
            ], yielding: [UserResponse].self)
                .first()
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { users in
                        continuation.resume(returning: users)
                    }
                )
        }
    }

    /// Check if two users are connected
    func checkConnection(userId1: String, userId2: String) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = client.subscribe(to: "connections:checkConnection", with: [
                "userId1": userId1,
                "userId2": userId2
            ], yielding: Bool.self)
                .first()
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { isConnected in
                        continuation.resume(returning: isConnected)
                    }
                )
        }
    }

    // MARK: Posts

    /// Fetch feed once
    func fetchFeed(userId: String, limit: Int? = nil, offset: Int? = nil) async throws -> [PostResponse] {
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = subscribeFeed(userId: userId, limit: limit, offset: offset)
                .first()
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { posts in
                        continuation.resume(returning: posts)
                    }
                )
        }
    }

    /// Fetch a single post once
    func fetchPost(postId: String) async throws -> PostResponse? {
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = subscribePost(postId: postId)
                .first()
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { post in
                        continuation.resume(returning: post)
                    }
                )
        }
    }

    /// Fetch posts by author once
    func fetchPostsByAuthor(authorId: String, limit: Int? = nil) async throws -> [PostResponse] {
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = subscribePostsByAuthor(authorId: authorId, limit: limit)
                .first()
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { posts in
                        continuation.resume(returning: posts)
                    }
                )
        }
    }

    // MARK: Comments

    /// Fetch comments for a post once
    func fetchComments(postId: String, limit: Int? = nil) async throws -> [CommentResponse] {
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = subscribeComments(postId: postId, limit: limit)
                .first()
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { comments in
                        continuation.resume(returning: comments)
                    }
                )
        }
    }

    // MARK: Messages

    /// Fetch conversations once
    func fetchConversations(userId: String) async throws -> [ConversationResponse] {
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = subscribeConversations(userId: userId)
                .first()
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { conversations in
                        continuation.resume(returning: conversations)
                    }
                )
        }
    }

    /// Fetch conversation between two users once
    func fetchConversationBetween(userId1: String, userId2: String) async throws -> ConversationResponse? {
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = client.subscribe(to: "messages:getConversationBetween", with: [
                "userId1": userId1,
                "userId2": userId2
            ], yielding: ConversationResponse?.self)
                .first()
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { conversation in
                        continuation.resume(returning: conversation)
                    }
                )
        }
    }

    // MARK: Mentions

    /// Fetch mention suggestions by text search
    func fetchMentionSuggestions(searchText: String) async throws -> [MentionSuggestion] {
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = client.subscribe(to: "mentions:getSuggestions", with: ["searchText": searchText], yielding: [MentionSuggestion].self)
                .first()
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { suggestions in
                        continuation.resume(returning: suggestions)
                    }
                )
        }
    }

    /// Fetch smart mention suggestions using vector search (relevance to post content)
    func fetchSmartMentionSuggestions(postId: String, searchText: String) async throws -> [MentionSuggestion] {
        return try await client.action("mentions:getSmartSuggestions", with: [
            "postId": postId,
            "searchText": searchText
        ])
    }

    // MARK: Suggested Matches

    /// Fetch suggested matches once (reads pre-computed daily matches)
    func fetchSuggestedMatches(userId: String) async throws -> [SuggestedMatchResponse] {
        return try await fetchSuggestedMatchesQuery(userId: userId)
    }

    // MARK: Connections

    /// Fetch connections for a user once
    func fetchConnections(userId: String) async throws -> [UserResponse] {
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = subscribeConnections(userId: userId)
                .first()
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { users in
                        continuation.resume(returning: users)
                    }
                )
        }
    }

    /// Get connection status between two users
    func getConnectionStatus(fromUserId: String, toUserId: String) async throws -> ConnectionStatus {
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = client.subscribe(to: "connections:getConnectionStatus", with: [
                "fromUserId": fromUserId,
                "toUserId": toUserId
            ], yielding: String.self)
                .first()
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { status in
                        continuation.resume(returning: ConnectionStatus(rawValue: status) ?? .none)
                    }
                )
        }
    }

    /// Fetch IDs of users I've sent pending requests to
    func fetchPendingSentIds(userId: String) async throws -> [String] {
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = client.subscribe(to: "connections:listPendingSentIds", with: [
                "userId": userId
            ], yielding: [String].self)
                .first()
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { ids in
                        continuation.resume(returning: ids)
                    }
                )
        }
    }

    // MARK: Portfolio

    /// Fetch portfolio items once
    func fetchPortfolioItems(userId: String) async throws -> [PortfolioItemResponse] {
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = subscribePortfolioItems(userId: userId)
                .first()
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { items in
                        continuation.resume(returning: items)
                    }
                )
        }
    }

    // MARK: Events

    /// Fetch a single event once
    func fetchEvent(id: String) async throws -> EventWithRsvpResponse? {
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = subscribeEvent(id: id)
                .first()
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { event in
                        continuation.resume(returning: event)
                    }
                )
        }
    }

    // MARK: Event Feedback

    /// Fetch events needing feedback once
    func fetchEventsNeedingFeedback(userId: String) async throws -> [EventWithRsvpResponse] {
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = subscribeEventsNeedingFeedback(userId: userId)
                .first()
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { events in
                        continuation.resume(returning: events)
                    }
                )
        }
    }
}

// MARK: - Connection Status

enum ConnectionStatus: String {
    case none = "none"
    case pendingSent = "pending_sent"
    case pendingReceived = "pending_received"
    case connected = "connected"
}

// MARK: - Response Types

struct UserMajorResponse: Codable, Hashable {
    let majorId: String
    let credentialLevel: Double
}

struct UserResponse: Codable, Identifiable, Hashable {
    let _id: String
    let clerkId: String
    let email: String?
    let phone: String?
    let name: String
    let headline: String?
    let avatarUrl: String?
    let universityId: String?
    let majors: [UserMajorResponse]?
    let graduationSemester: String?
    let programs: [String]?
    let skills: [String]?
    let interests: [String]?
    let lookingFor: String?
    let canHelpWith: String?
    let currentProject: String?
    let socialLinks: SocialLinksResponse?
    let role: String?
    let platformRole: String?
    let status: String?
    let isOnboarded: Bool
    let createdAt: Double
    let updatedAt: Double

    var id: String { _id }

    struct SocialLinksResponse: Codable, Hashable {
        let linkedin: String?
        let instagram: String?
        let twitter: String?
        let github: String?
        let website: String?
    }
}

// MARK: - Suggested Match Response

struct SuggestedMatchResponse: Codable, Identifiable, Hashable {
    let _id: String
    let clerkId: String
    let email: String?
    let name: String
    let headline: String?
    let avatarUrl: String?
    let universityId: String?
    let currentProject: String?
    let lookingFor: String?
    let canHelpWith: String?
    let skills: [String]?
    let interests: [String]?
    let role: String?
    let isOnboarded: Bool
    let createdAt: Double
    let updatedAt: Double
    let matchReason: String

    var id: String { _id }

    func toUserResponse() -> UserResponse {
        UserResponse(
            _id: _id,
            clerkId: clerkId,
            email: email,
            phone: nil,
            name: name,
            headline: headline,
            avatarUrl: avatarUrl,
            universityId: universityId,
            majors: nil,
            graduationSemester: nil,
            programs: nil,
            skills: skills,
            interests: interests,
            lookingFor: lookingFor,
            canHelpWith: canHelpWith,
            currentProject: currentProject,
            socialLinks: nil,
            role: role,
            platformRole: nil,
            status: nil,
            isOnboarded: isOnboarded,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

// MARK: - Search Response

struct SearchResultItem: Codable, Identifiable {
    let userId: String
    let explanation: String
    let relevanceScore: Double
    let mutualConnectionCount: Int?
    let mutualConnectionNames: [String]?
    let connectionStatus: String?
    let isAIEnhanced: Bool?

    var id: String { userId }

    var parsedConnectionStatus: ConnectionStatus {
        guard let status = connectionStatus else { return .none }
        return ConnectionStatus(rawValue: status) ?? .none
    }
}

struct QuickSearchResponse: Codable {
    let results: [SearchResultItem]
}

struct AISearchResponse: Codable {
    let thinking: String
    let results: [SearchResultItem]
}

struct VectorSearchResponse: Codable {
    let results: [SearchResultItem]
}

// MARK: - Search Session Response (streaming)

struct SearchSessionResponse: Codable, Identifiable {
    let _id: String
    let userId: String
    let query: String
    let status: String
    let thinkingText: String?
    let results: String?       // JSON string of StreamingSearchResult[]
    let resultCount: Double?
    let createdAt: Double
    let updatedAt: Double

    var id: String { _id }

    var parsedResults: [StreamingSearchResult] {
        guard let results = results, !results.isEmpty else { return [] }
        do {
            return try JSONDecoder().decode([StreamingSearchResult].self, from: Data(results.utf8))
        } catch {
            return []
        }
    }
}

struct StreamingSearchResult: Codable, Identifiable {
    let userId: String
    let explanation: String
    let relevanceScore: Double
    let mutualConnectionCount: Int?
    let mutualConnectionNames: [String]?
    let connectionStatus: String?
    let isAIEnhanced: Bool?

    var id: String { userId }

    func toSearchResultItem() -> SearchResultItem {
        SearchResultItem(
            userId: userId,
            explanation: explanation,
            relevanceScore: relevanceScore,
            mutualConnectionCount: mutualConnectionCount,
            mutualConnectionNames: mutualConnectionNames,
            connectionStatus: connectionStatus,
            isAIEnhanced: isAIEnhanced
        )
    }
}

struct NameAutocompleteResult: Codable, Identifiable {
    let _id: String
    let name: String
    let headline: String?
    let avatarUrl: String?

    var id: String { _id }
}

struct SearchChatResponse: Codable, Identifiable {
    let _id: String
    let userId: String
    let title: String
    let lastQueryAt: Double
    let lastQueryPreview: String?
    let createdAt: Double
    var id: String { _id }
}

struct SearchMessageResponse: Codable, Identifiable {
    let _id: String
    let chatId: String
    let role: String
    let content: String
    let results: String?
    let createdAt: Double
    var id: String { _id }
}

// MARK: - Mock Data for Suggested Matches

extension SuggestedMatchResponse {
    static let mock = SuggestedMatchResponse(
        _id: "match_1",
        clerkId: "clerk_match_1",
        email: "sarah@example.com",
        name: "Sarah Chen",
        headline: "Co-founder @ TechStartup",
        avatarUrl: nil,
        universityId: nil,
        currentProject: "DevTools",
        lookingFor: "Designer, marketing help",
        canHelpWith: "Engineering, APIs",
        skills: ["React", "Node.js", "AWS"],
        interests: ["DevTools", "AI"],
        role: "student",
        isOnboarded: true,
        createdAt: Date().timeIntervalSince1970 * 1000,
        updatedAt: Date().timeIntervalSince1970 * 1000,
        matchReason: "Sarah is looking for a designer and you have design skills"
    )
}

// MARK: - Mock Data for Previews

extension UserResponse {
    static let mock = UserResponse(
        _id: "mock_1",
        clerkId: "clerk_mock_1",
        email: "kenny@onjunto.com",
        phone: nil,
        name: "Kenny Morales",
        headline: "Building FindU - College decision platform",
        avatarUrl: nil,
        universityId: nil,
        majors: nil,
        graduationSemester: "Spring 2027",
        programs: nil,
        skills: ["Swift", "iOS", "Product"],
        interests: ["EdTech", "AI", "Mobile"],
        lookingFor: "Technical co-founder, iOS developers",
        canHelpWith: "Startup strategy, pitch decks",
        currentProject: "FindU",
        socialLinks: SocialLinksResponse(
            linkedin: "https://linkedin.com/in/kennymorales",
            instagram: nil,
            twitter: "https://twitter.com/knnymrls",
            github: "https://github.com/knnymrls",
            website: "https://onjunto.com"
        ),
        role: "student",
        platformRole: "superadmin",
        status: "active",
        isOnboarded: true,
        createdAt: Date().timeIntervalSince1970 * 1000,
        updatedAt: Date().timeIntervalSince1970 * 1000
    )

    static let mockList: [UserResponse] = [
        mock,
        UserResponse(
            _id: "mock_2",
            clerkId: "clerk_mock_2",
            email: "sarah@example.com",
            phone: nil,
            name: "Sarah Chen",
            headline: "Full-stack developer | React & Node",
            avatarUrl: nil,
            universityId: nil,
            majors: nil,
            graduationSemester: nil,
            programs: nil,
            skills: ["React", "TypeScript", "Node.js"],
            interests: ["FoodTech", "AI"],
            lookingFor: "Co-founder with marketing skills",
            canHelpWith: "Frontend, API design",
            currentProject: "AI recipe generator",
            socialLinks: nil,
            role: "student",
            platformRole: nil,
            status: nil,
            isOnboarded: true,
            createdAt: Date().timeIntervalSince1970 * 1000,
            updatedAt: Date().timeIntervalSince1970 * 1000
        ),
        UserResponse(
            _id: "mock_3",
            clerkId: "clerk_mock_3",
            email: "marcus@example.com",
            phone: nil,
            name: "Marcus Williams",
            headline: "UX Designer | Previously at Google",
            avatarUrl: nil,
            universityId: nil,
            majors: nil,
            graduationSemester: nil,
            programs: nil,
            skills: ["Figma", "Design Systems"],
            interests: ["DesignOps", "Mobile"],
            lookingFor: "Developers to collaborate with",
            canHelpWith: "UI/UX design",
            currentProject: "Design system for startups",
            socialLinks: nil,
            role: "student",
            platformRole: nil,
            status: nil,
            isOnboarded: true,
            createdAt: Date().timeIntervalSince1970 * 1000,
            updatedAt: Date().timeIntervalSince1970 * 1000
        )
    ]
}

struct EventResponse: Codable, Identifiable, Hashable {
    let _id: String
    let title: String
    let description: String?
    let date: Double
    let endDate: Double?
    let location: String?
    let type: String
    let imageUrl: String?
    let createdBy: String
    let createdAt: Double
    // Preview fields from listUpcoming
    let host: EventHost?
    let goingCount: Int?
    let attendeePreviews: [AttendeePreview]?

    var id: String { _id }

    var dateValue: Date { Date(timeIntervalSince1970: date / 1000) }
    var endDateValue: Date? { endDate.map { Date(timeIntervalSince1970: $0 / 1000) } }

    var eventType: EventType {
        EventType(rawValue: type) ?? .inPerson
    }

    struct EventHost: Codable, Hashable {
        let id: String
        let name: String
        let avatarUrl: String?
    }

    struct AttendeePreview: Codable, Hashable, Identifiable {
        let id: String
        let name: String
        let avatarUrl: String?
    }

    enum EventType: String, Codable {
        case inPerson = "in_person"
        case online = "online"
        case hybrid = "hybrid"

        var displayName: String {
            switch self {
            case .inPerson: return "In Person"
            case .online: return "Online"
            case .hybrid: return "Hybrid"
            }
        }

        var iconName: String {
            switch self {
            case .inPerson: return "person.2.fill"
            case .online: return "video.fill"
            case .hybrid: return "person.2.wave.2.fill"
            }
        }
    }
}

// MARK: - Mock Data for Events

extension EventResponse {
    static let mockList: [EventResponse] = [
        EventResponse(
            _id: "event_1",
            title: "JUNTO SPEED NETWORKING",
            description: "Meet other users in quick 5-minute conversations. Rotate through and connect with founders, designers, and developers building cool stuff in Lincoln.\n\nExact location will be shared after you RSVP.",
            date: Date().addingTimeInterval(86400 * 3).timeIntervalSince1970 * 1000,
            endDate: Date().addingTimeInterval(86400 * 3 + 7200).timeIntervalSince1970 * 1000,
            location: "Lincoln, NE",
            type: "in_person",
            imageUrl: "https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800&h=600&fit=crop",
            createdBy: "mock_1",
            createdAt: Date().timeIntervalSince1970 * 1000,
            host: EventHost(id: "mock_1", name: "Kenny Morales", avatarUrl: nil),
            goingCount: 5,
            attendeePreviews: [
                AttendeePreview(id: "mock_2", name: "Sarah Chen", avatarUrl: nil),
                AttendeePreview(id: "mock_3", name: "Marcus Williams", avatarUrl: nil),
                AttendeePreview(id: "mock_4", name: "Wilson Overfield", avatarUrl: nil)
            ]
        ),
        EventResponse(
            _id: "event_2",
            title: "Weekly User Standup",
            description: "30 minutes every Saturday. Share what you shipped this week, what you're working on next, and where you're stuck.",
            date: Date().addingTimeInterval(86400 * 7).timeIntervalSince1970 * 1000,
            endDate: nil,
            location: nil,
            type: "online",
            imageUrl: nil,
            createdBy: "mock_1",
            createdAt: Date().timeIntervalSince1970 * 1000,
            host: EventHost(id: "mock_1", name: "Kenny Morales", avatarUrl: nil),
            goingCount: 12,
            attendeePreviews: nil
        )
    ]
}

struct EventWithRsvpResponse: Codable, Identifiable {
    let _id: String
    let title: String
    let description: String?
    let date: Double
    let endDate: Double?
    let location: String?
    let fullAddress: String?
    let type: String
    let imageUrl: String?
    let createdBy: String
    let createdAt: Double
    let goingCount: Int
    let interestedCount: Int
    let host: EventHost?
    let attendeePreviews: [AttendeePreview]?

    var id: String { _id }

    var dateValue: Date { Date(timeIntervalSince1970: date / 1000) }
    var endDateValue: Date? { endDate.map { Date(timeIntervalSince1970: $0 / 1000) } }

    var eventType: EventResponse.EventType {
        EventResponse.EventType(rawValue: type) ?? .inPerson
    }

    struct EventHost: Codable, Hashable {
        let id: String
        let name: String
        let avatarUrl: String?
        let headline: String?
    }

    struct AttendeePreview: Codable, Hashable, Identifiable {
        let id: String
        let name: String
        let avatarUrl: String?
    }
}

struct EventAttendee: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let avatarUrl: String?
    let headline: String?
    let status: String

    var isGoing: Bool { status == "going" }
}

struct EventRsvpResponse: Codable {
    let _id: String
    let eventId: String
    let userId: String
    let status: String
    let createdAt: Double

    var rsvpStatus: RsvpStatus {
        RsvpStatus(rawValue: status) ?? .notGoing
    }

    enum RsvpStatus: String {
        case going = "going"
        case interested = "interested"
        case notGoing = "not_going"
    }
}

struct EventFeedbackResponse: Codable {
    let _id: String
    let eventId: String
    let userId: String
    let rating: Int
    let improvements: [String]
    let wantToConnectWith: [String]
    let createdAt: Double
}

// MARK: - Input Types

struct MajorInput {
    let majorId: String
    let credentialLevel: Int
}

struct UserInput {
    let clerkId: String
    var email: String?
    var phone: String?
    let name: String
    var headline: String?
    var avatarUrl: String?
    var universityId: String?
    var majors: [MajorInput]?
    var graduationSemester: String?
    var programs: [String]?
    var skills: [String]?
    var interests: [String]?
    var lookingFor: String?
    var canHelpWith: String?
    var currentProject: String?
    var socialLinks: SocialLinksInput?
    var role: String?
    var platformRole: String?

    struct SocialLinksInput {
        var linkedin: String?
        var instagram: String?
        var twitter: String?
        var github: String?
        var website: String?
    }

    func toArgs() -> [String: (any ConvexEncodable)?] {
        var args: [String: (any ConvexEncodable)?] = [
            "clerkId": clerkId,
            "name": name
        ]
        if let email = email { args["email"] = email }
        if let phone = phone { args["phone"] = phone }
        if let headline = headline { args["headline"] = headline }
        if let avatarUrl = avatarUrl { args["avatarUrl"] = avatarUrl }
        if let universityId = universityId { args["universityId"] = universityId }
        if let graduationSemester = graduationSemester { args["graduationSemester"] = graduationSemester }
        if let currentProject = currentProject { args["currentProject"] = currentProject }
        if let lookingFor = lookingFor { args["lookingFor"] = lookingFor }
        if let canHelpWith = canHelpWith { args["canHelpWith"] = canHelpWith }
        if let role = role { args["role"] = role }
        if let platformRole = platformRole { args["platformRole"] = platformRole }
        if let skills = skills {
            let arr: [ConvexEncodable?] = skills.map { $0 as ConvexEncodable? }
            args["skills"] = arr
        }
        if let interests = interests {
            let arr: [ConvexEncodable?] = interests.map { $0 as ConvexEncodable? }
            args["interests"] = arr
        }
        if let programs = programs {
            let arr: [ConvexEncodable?] = programs.map { $0 as ConvexEncodable? }
            args["programs"] = arr
        }
        if let majors = majors {
            let arr: [ConvexEncodable?] = majors.map { major in
                [
                    "majorId": major.majorId as ConvexEncodable?,
                    "credentialLevel": Double(major.credentialLevel) as ConvexEncodable?
                ] as ConvexEncodable?
            }
            args["majors"] = arr
        }
        return args
    }
}

// MARK: - Post Types

struct PostResponse: Codable, Identifiable, Hashable {
    let _id: String
    let authorId: String
    let content: String
    let category: String
    let imageUrl: String?
    let imageUrls: [String]?
    let linkUrl: String?
    let gifUrl: String?
    let createdAt: Double
    let updatedAt: Double
    let author: UserResponse?
    let commentCount: Int?
    let recentCommenters: [RecentCommenter]?

    var id: String { _id }

    struct RecentCommenter: Codable, Hashable {
        let _id: String
        let name: String
        let avatarUrl: String?
    }

    var createdDate: Date { Date(timeIntervalSince1970: createdAt / 1000) }
    var updatedDate: Date { Date(timeIntervalSince1970: updatedAt / 1000) }

    /// All image URLs (combines legacy imageUrl with imageUrls array)
    var allImageUrls: [String] {
        var urls: [String] = []
        if let imageUrls = imageUrls, !imageUrls.isEmpty {
            urls = imageUrls
        } else if let imageUrl = imageUrl {
            urls = [imageUrl]
        }
        return urls
    }

    var categoryType: PostCategory {
        PostCategory(rawValue: category) ?? .sharing
    }

    enum PostCategory: String, Codable, CaseIterable {
        case asking = "asking"
        case sharing = "sharing"
        case lookingFor = "looking_for"

        var displayName: String {
            switch self {
            case .asking: return "Asking"
            case .sharing: return "Sharing"
            case .lookingFor: return "Looking For"
            }
        }

        var iconName: String {
            switch self {
            case .asking: return "questionmark.circle"
            case .sharing: return "lightbulb"
            case .lookingFor: return "magnifyingglass"
            }
        }

        var customIconName: String {
            switch self {
            case .asking: return "content.asking"
            case .sharing: return "content.sharing"
            case .lookingFor: return "content.looking"
            }
        }
    }
}

// MARK: - Mock Data for Posts

extension PostResponse {
    static let mock = PostResponse(
        _id: "post_1",
        authorId: "mock_1",
        content: "Looking for feedback on my pitch deck for FindU. Anyone have experience with EdTech fundraising?",
        category: "asking",
        imageUrl: nil,
        imageUrls: nil,
        linkUrl: nil,
        gifUrl: nil,
        createdAt: Date().timeIntervalSince1970 * 1000,
        updatedAt: Date().timeIntervalSince1970 * 1000,
        author: UserResponse.mock,
        commentCount: 3,
        recentCommenters: [
            RecentCommenter(_id: "mock_2", name: "Sarah Chen", avatarUrl: nil),
            RecentCommenter(_id: "mock_3", name: "Marcus Williams", avatarUrl: nil)
        ]
    )

    static let mockList: [PostResponse] = [
        mock,
        PostResponse(
            _id: "post_2",
            authorId: "mock_2",
            content: "Just shipped v2 of our recipe AI! Now with meal planning and grocery lists. Would love beta testers.",
            category: "sharing",
            imageUrl: nil,
            imageUrls: nil,
            linkUrl: "https://recipeai.app",
            gifUrl: nil,
            createdAt: Date().addingTimeInterval(-3600).timeIntervalSince1970 * 1000,
            updatedAt: Date().addingTimeInterval(-3600).timeIntervalSince1970 * 1000,
            author: UserResponse.mockList[1],
            commentCount: 5,
            recentCommenters: [
                RecentCommenter(_id: "mock_1", name: "Kenny Morales", avatarUrl: nil)
            ]
        ),
        PostResponse(
            _id: "post_3",
            authorId: "mock_3",
            content: "Looking for a technical co-founder for a design tools startup. Need someone strong in React and real-time collaboration.",
            category: "looking_for",
            imageUrl: nil,
            imageUrls: nil,
            linkUrl: nil,
            gifUrl: nil,
            createdAt: Date().addingTimeInterval(-7200).timeIntervalSince1970 * 1000,
            updatedAt: Date().addingTimeInterval(-7200).timeIntervalSince1970 * 1000,
            author: UserResponse.mockList[2],
            commentCount: 8,
            recentCommenters: [
                RecentCommenter(_id: "mock_1", name: "Kenny Morales", avatarUrl: nil),
                RecentCommenter(_id: "mock_2", name: "Sarah Chen", avatarUrl: nil)
            ]
        )
    ]
}

struct CommentResponse: Codable, Identifiable, Hashable {
    let _id: String
    let postId: String
    let authorId: String
    let content: String
    let mentions: [String]?
    let imageUrl: String?
    let linkUrl: String?
    let gifUrl: String?
    let createdAt: Double
    let author: UserResponse?
    let mentionedUsers: [UserResponse]?

    var id: String { _id }

    var createdDate: Date { Date(timeIntervalSince1970: createdAt / 1000) }
}

// MARK: - Mock Data for Comments

extension CommentResponse {
    static let mock = CommentResponse(
        _id: "comment_1",
        postId: "post_1",
        authorId: "mock_2",
        content: "Happy to help! DM me and I'll share some resources.",
        mentions: nil,
        imageUrl: nil,
        linkUrl: nil,
        gifUrl: nil,
        createdAt: Date().addingTimeInterval(-1800).timeIntervalSince1970 * 1000,
        author: UserResponse.mockList[1],
        mentionedUsers: nil
    )

    static let mockList: [CommentResponse] = [
        mock,
        CommentResponse(
            _id: "comment_2",
            postId: "post_1",
            authorId: "mock_3",
            content: "I know @Sarah Chen has done this before - might be worth connecting!",
            mentions: ["mock_2"],
            imageUrl: nil,
            linkUrl: nil,
            gifUrl: nil,
            createdAt: Date().addingTimeInterval(-900).timeIntervalSince1970 * 1000,
            author: UserResponse.mockList[2],
            mentionedUsers: [UserResponse.mockList[1]]
        )
    ]
}

struct PostInput {
    let content: String
    let category: PostResponse.PostCategory
    var imageUrls: [String]?
    var linkUrl: String?
    var gifUrl: String?
    var mentions: [String]?

    func toArgs(authorId: String) -> [String: (any ConvexEncodable)?] {
        var args: [String: (any ConvexEncodable)?] = [
            "authorId": authorId,
            "content": content,
            "category": category.rawValue
        ]
        if let imageUrls = imageUrls, !imageUrls.isEmpty {
            // Cast [String] to [ConvexEncodable?] for proper encoding
            let encodableUrls: [ConvexEncodable?] = imageUrls.map { $0 as ConvexEncodable? }
            args["imageUrls"] = encodableUrls
        }
        if let linkUrl = linkUrl { args["linkUrl"] = linkUrl }
        if let gifUrl = gifUrl { args["gifUrl"] = gifUrl }
        if let mentions = mentions, !mentions.isEmpty {
            let encodableMentions: [ConvexEncodable?] = mentions.map { $0 as ConvexEncodable? }
            args["mentions"] = encodableMentions
        }
        return args
    }
}

struct CommentInput {
    let postId: String
    let content: String
    var mentions: [String]?
    var imageUrl: String?
    var linkUrl: String?
    var gifUrl: String?

    func toArgs(authorId: String) -> [String: (any ConvexEncodable)?] {
        var args: [String: (any ConvexEncodable)?] = [
            "postId": postId,
            "authorId": authorId,
            "content": content
        ]
        if let imageUrl = imageUrl { args["imageUrl"] = imageUrl }
        if let linkUrl = linkUrl { args["linkUrl"] = linkUrl }
        if let gifUrl = gifUrl { args["gifUrl"] = gifUrl }
        if let mentions = mentions, !mentions.isEmpty {
            let encodableMentions: [ConvexEncodable?] = mentions.map { $0 as ConvexEncodable? }
            args["mentions"] = encodableMentions
        }
        return args
    }
}

struct MentionSuggestion: Codable, Identifiable, Hashable {
    let _id: String
    let name: String
    let headline: String?
    let avatarUrl: String?

    var id: String { _id }
}

// MARK: - Conversation Response

struct ConversationResponse: Codable, Identifiable {
    let _id: String
    let participant1Id: String
    let participant2Id: String
    let lastMessageAt: Double
    let lastMessagePreview: String?
    let lastMessageSenderId: String?
    let participant1UnreadCount: Int
    let participant2UnreadCount: Int
    let createdAt: Double
    let otherParticipant: UserResponse?
    let unreadCount: Int?
    let status: String?
    let initiatorId: String?
    let isRequest: Bool?
    let isSentRequest: Bool?

    var id: String { _id }
    var lastMessageDate: Date { Date(timeIntervalSince1970: lastMessageAt / 1000) }
}

// MARK: - Message Response

struct MessageResponse: Codable, Identifiable {
    let _id: String
    let conversationId: String
    let senderId: String
    let content: String
    let gifUrl: String?
    let readAt: Double?
    let createdAt: Double

    var id: String { _id }
    var createdDate: Date { Date(timeIntervalSince1970: createdAt / 1000) }
    var isRead: Bool { readAt != nil }
}

// MARK: - Notification Response

struct NotificationResponse: Codable, Identifiable {
    let _id: String
    let recipientId: String
    let type: String
    let title: String
    let body: String?
    let data: NotificationData?
    let readAt: Double?
    let createdAt: Double
    let sender: SenderInfo?

    var id: String { _id }
    var isRead: Bool { readAt != nil }
    var createdDate: Date { Date(timeIntervalSince1970: createdAt / 1000) }

    struct NotificationData: Codable {
        let postId: String?
        let commentId: String?
        let senderId: String?
        let connectionId: String?
        let eventId: String?
        let conversationId: String?
    }

    struct SenderInfo: Codable {
        let _id: String
        let name: String
        let avatarUrl: String?
    }
}

// MARK: - Portfolio Item Response

struct PortfolioItemResponse: Codable, Identifiable, Hashable {
    let _id: String
    let userId: String
    let type: String
    let title: String?
    let url: String?
    let description: String?
    let imageUrls: [String]?
    let organization: String?
    let startDate: String?
    let endDate: String?
    let size: String?
    let order: Double
    let createdAt: Double
    let updatedAt: Double

    var id: String { _id }

    enum PortfolioType: String {
        case github
        case gallery
        case link
        case experience
    }

    var portfolioType: PortfolioType {
        PortfolioType(rawValue: type) ?? .link
    }

    enum PortfolioSize: String {
        case small
        case medium
        case large
    }

    var effectiveSize: PortfolioSize {
        PortfolioSize(rawValue: size ?? "medium") ?? .medium
    }
}
