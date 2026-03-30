//
//  SettingsViewModel.swift
//  junto
//
//  Handles settings actions: sign out, delete account, notification status
//

import Foundation
import Clerk
import UserNotifications

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var notificationsEnabled = false
    @Published var isCheckingNotifications = true
    @Published var showDeleteConfirmation = false
    @Published var isDeleting = false

    func checkNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationsEnabled = settings.authorizationStatus == .authorized
        isCheckingNotifications = false
    }

    func signOut() {
        OnboardingViewModel.clearAllStorage()
        Task { try? await Clerk.shared.signOut() }
    }

    func deleteAccount() async {
        isDeleting = true
        // TODO: Add Convex deleteUser mutation when backend supports it
        // For now, sign out + clear local data
        await PushNotificationManager.shared.unregister()
        OnboardingViewModel.clearAllStorage()
        try? await Clerk.shared.signOut()
        isDeleting = false
    }
}
