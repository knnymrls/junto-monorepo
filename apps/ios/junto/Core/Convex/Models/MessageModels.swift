//
//  MessageModels.swift
//  mkrs-world
//
//  Conversation and message model types.
//

import Foundation
import ConvexMobile
import Combine
import UIKit


struct SearchMessageResponse: Codable, Identifiable {
    let _id: String
    let chatId: String
    let role: String
    let content: String
    let results: String?
    let createdAt: Double
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

struct MessageReaction: Codable, Hashable {
    let userId: String
    let emoji: String
}


struct MessageResponse: Codable, Identifiable {
    let _id: String
    let conversationId: String
    let senderId: String
    let content: String
    let gifUrl: String?
    let readAt: Double?
    let createdAt: Double
    let editedAt: Double?
    let deletedAt: Double?
    let replyToId: String?
    let reactions: [MessageReaction]?

    var id: String { _id }
    var createdDate: Date { Date(timeIntervalSince1970: createdAt / 1000) }
    var isRead: Bool { readAt != nil }
    var isEdited: Bool { editedAt != nil }
    var isDeleted: Bool { deletedAt != nil }

    /// Reactions grouped by emoji, preserving first-seen order.
    var groupedReactions: [(emoji: String, userIds: [String])] {
        guard let reactions, !reactions.isEmpty else { return [] }
        var order: [String] = []
        var map: [String: [String]] = [:]
        for r in reactions {
            if map[r.emoji] == nil { order.append(r.emoji) }
            map[r.emoji, default: []].append(r.userId)
        }
        return order.map { ($0, map[$0] ?? []) }
    }
}
