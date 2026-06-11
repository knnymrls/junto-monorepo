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
    /// User-facing failure from an action on a notification — the view alerts.
    @Published var actionError: String?

    private let convex = ConvexClientManager.shared
    private var cancellables = Set<AnyCancellable>()

    func subscribe(userId: String) {
        guard cancellables.isEmpty else { return }
        isLoading = true

        convex.subscribeNotifications(userId: userId, limit: 50)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("NotificationsViewModel: subscription ended: \(error)")
                        // Drop the dead subscription so the next subscribe()
                        // (tab revisit) reattaches instead of bailing on the
                        // cancellables.isEmpty guard.
                        self?.cancellables.removeAll()
                        self?.isLoading = false
                    }
                },
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
        do {
            try await convex.markAllNotificationsRead(userId: userId)
        } catch {
            actionError = "Couldn't mark notifications as read. Try again."
        }
    }

    func remove(_ notification: NotificationResponse) async {
        do {
            try await convex.removeNotification(notificationId: notification._id)
        } catch {
            actionError = "Couldn't remove the notification. Try again."
        }
    }

    func acceptConnection(_ notification: NotificationResponse) async {
        guard let connectionId = notification.data?.connectionId else { return }
        do {
            // The accept must succeed before the notification is rewritten —
            // the old try? chain recorded "You accepted..." even when the
            // mutation failed and the connection never happened.
            try await convex.acceptConnectionRequest(connectionId: connectionId)
        } catch {
            actionError = "Couldn't accept the connection request. Try again."
            return
        }
        let name = notification.sender?.name ?? "their"
        try? await convex.updateNotificationTitle(
            notificationId: notification._id,
            title: "You accepted \(name)'s connection request"
        )
        try? await convex.markNotificationRead(notificationId: notification._id)
    }

    func rejectConnection(_ notification: NotificationResponse) async {
        guard let connectionId = notification.data?.connectionId else { return }
        do {
            try await convex.rejectConnectionRequest(connectionId: connectionId)
        } catch {
            actionError = "Couldn't decline the connection request. Try again."
            return
        }
        try? await convex.removeNotification(notificationId: notification._id)
    }

    var hasUnread: Bool {
        notifications.contains { !$0.isRead }
    }
}
