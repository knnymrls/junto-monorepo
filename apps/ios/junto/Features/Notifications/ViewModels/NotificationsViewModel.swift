//
//  NotificationsViewModel.swift
//  mkrs-world
//
//  ViewModel for the notifications tab
//

import Foundation
import Combine

@MainActor
class NotificationsViewModel: ObservableObject {
    @Published var notifications: [NotificationResponse] = []
    @Published var isLoading = false

    private let convex = ConvexClientManager.shared
    private var cancellables = Set<AnyCancellable>()

    func subscribe(userId: String) {
        guard cancellables.isEmpty else { return }
        isLoading = true

        convex.subscribeNotifications(userId: userId, limit: 50)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] notifications in
                    self?.notifications = notifications.filter { notif in
                        notif.type != "new_message" && notif.type != "message_request"
                    }
                    self?.isLoading = false
                }
            )
            .store(in: &cancellables)
    }

    func markAsRead(_ notification: NotificationResponse) async {
        guard !notification.isRead else { return }
        try? await convex.markNotificationRead(notificationId: notification._id)
    }

    func markAllAsRead(userId: String) async {
        try? await convex.markAllNotificationsRead(userId: userId)
    }

    func remove(_ notification: NotificationResponse) async {
        try? await convex.removeNotification(notificationId: notification._id)
    }

    func acceptConnection(_ notification: NotificationResponse) async {
        guard let connectionId = notification.data?.connectionId else { return }
        try? await convex.acceptConnectionRequest(connectionId: connectionId)
        let name = notification.sender?.name ?? "their"
        try? await convex.updateNotificationTitle(
            notificationId: notification._id,
            title: "You accepted \(name)'s connection request"
        )
        try? await convex.markNotificationRead(notificationId: notification._id)
    }

    func rejectConnection(_ notification: NotificationResponse) async {
        guard let connectionId = notification.data?.connectionId else { return }
        try? await convex.rejectConnectionRequest(connectionId: connectionId)
        try? await convex.removeNotification(notificationId: notification._id)
    }

    var hasUnread: Bool {
        notifications.contains { !$0.isRead }
    }
}
