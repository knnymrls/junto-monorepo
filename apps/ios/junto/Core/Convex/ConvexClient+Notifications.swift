//
//  ConvexClient+Notifications.swift
//  mkrs-world
//
//  In-app notifications, preferences, and device tokens.
//

import Foundation
import ConvexMobile
import Combine
import UIKit

extension ConvexClientManager {

    // MARK: Notifications

    /// Subscribe to notifications for a user
    func subscribeNotifications(userId: String, limit: Int? = nil) -> AnyPublisher<[NotificationResponse], ClientError> {
        var args: [String: (any ConvexEncodable)?] = ["userId": userId]
        if let limit { args["limit"] = Double(limit) }
        return client.subscribe(to: "notifications:listForUser", with: args, yielding: [NotificationResponse].self)
    }


    /// Subscribe to the user's muted notification categories.
    func subscribeNotificationPreferences(userId: String) -> AnyPublisher<[String], ClientError> {
        return client.subscribe(to: "notifications:getPreferences", with: ["userId": userId], yielding: [String].self)
    }
}

extension ConvexClientManager {

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


    func fetchNotificationPreferences(userId: String) async throws -> [String] {
        return try await queryOnce(subscribeNotificationPreferences(userId: userId))
    }


    func setNotificationPreferences(userId: String, mutedCategories: [String]) async throws {
        let categories: [ConvexEncodable?] = mutedCategories.map { $0 as ConvexEncodable? }
        let _: String? = try await client.mutation("notifications:setPreferences", with: [
            "userId": userId,
            "mutedCategories": categories
        ])
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

    /// Subscribe to unread notification count
    func subscribeUnreadCount(userId: String) -> AnyPublisher<Int, ClientError> {
        return client.subscribe(to: "notifications:getUnreadCount", with: ["userId": userId], yielding: Int.self)
    }
}
