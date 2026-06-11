//
//  ConvexClient+Messages.swift
//  mkrs-world
//
//  Conversations, messages, and typing indicators.
//

import Foundation
import ConvexMobile
import Combine
import UIKit

extension ConvexClientManager {

    /// Subscribe to messages for a search chat
    func subscribeSearchMessages(chatId: String) -> AnyPublisher<[SearchMessageResponse], ClientError> {
        return client.subscribe(to: "searchChats:getMessages", with: ["chatId": chatId], yielding: [SearchMessageResponse].self)
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
}

extension ConvexClientManager {

    // MARK: Messages

    func sendMessage(senderId: String, recipientId: String, content: String, gifUrl: String? = nil, replyToId: String? = nil) async throws -> String {
        var args: [String: (any ConvexEncodable)?] = [
            "senderId": senderId,
            "recipientId": recipientId,
            "content": content
        ]
        if let gifUrl { args["gifUrl"] = gifUrl }
        if let replyToId { args["replyToId"] = replyToId }
        return try await client.mutation("messages:sendMessage", with: args)
    }


    func editMessage(messageId: String, userId: String, content: String) async throws {
        let _: String? = try await client.mutation("messages:editMessage", with: [
            "messageId": messageId,
            "userId": userId,
            "content": content
        ])
    }


    func deleteMessage(messageId: String, userId: String) async throws {
        let _: String? = try await client.mutation("messages:deleteMessage", with: [
            "messageId": messageId,
            "userId": userId
        ])
    }


    func toggleMessageReaction(messageId: String, userId: String, emoji: String) async throws {
        let _: String? = try await client.mutation("messages:toggleReaction", with: [
            "messageId": messageId,
            "userId": userId,
            "emoji": emoji
        ])
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
}

extension ConvexClientManager {

    // MARK: Messages

    /// Fetch conversations once
    func fetchConversations(userId: String) async throws -> [ConversationResponse] {
        return try await queryOnce(subscribeConversations(userId: userId))
    }


    /// Fetch conversation between two users once
    func fetchConversationBetween(userId1: String, userId2: String) async throws -> ConversationResponse? {
        return try await queryOnce("messages:getConversationBetween", with: [
                "userId1": userId1,
                "userId2": userId2
            ], yielding: ConversationResponse?.self)
    }
}
