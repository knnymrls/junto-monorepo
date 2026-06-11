//
//  NotificationModels.swift
//  mkrs-world
//
//  Notification model types.
//

import Foundation
import ConvexMobile
import Combine
import UIKit


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
