//
//  PushNotificationManager.swift
//  junto
//
//  Handles APNs registration and device token management
//

import Foundation
import UIKit
import UserNotifications

@MainActor
class PushNotificationManager: NSObject, ObservableObject {
    static let shared = PushNotificationManager()

    @Published var isRegistered = false
    private var deviceToken: String?
    private var pendingUserId: String?
    private let convex = ConvexClientManager.shared

    func requestPermissionAndRegister(userId: String) {
        pendingUserId = userId

        // If we already have a token, just register it
        if let token = deviceToken {
            Task { await registerWithBackend(userId: userId) }
            return
        }

        // Otherwise request permission and wait for the token
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                    AnalyticsService.shared.track(.notificationsPushEnabled)
                } else {
                    AnalyticsService.shared.track(.notificationsPushDenied)
                }
            }
        }
    }

    func handleToken(_ tokenData: Data) {
        deviceToken = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        isRegistered = true

        // If we have a pending user, register the token now
        if let userId = pendingUserId {
            Task { await registerWithBackend(userId: userId) }
        }
    }

    func registerWithBackend(userId: String, attempt: Int = 0) async {
        guard let token = deviceToken else { return }
        let device = UIDevice.current
        do {
            try await convex.registerDeviceToken(
                userId: userId,
                token: token,
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                deviceModel: device.model,
                osVersion: device.systemVersion
            )
        } catch {
            // One transient failure used to mean this install never received a
            // push again — retry with backoff (3 attempts total).
            print("PushNotificationManager: register failed (attempt \(attempt + 1)): \(error)")
            guard attempt < 2 else { return }
            try? await Task.sleep(nanoseconds: UInt64(5 * (attempt + 1)) * 1_000_000_000)
            await registerWithBackend(userId: userId, attempt: attempt + 1)
        }
    }

    func unregister() async {
        guard let token = deviceToken else { return }
        do {
            try await convex.removeDeviceToken(token: token)
        } catch {
            // The backend still holds this token: the device would keep
            // getting the signed-out account's pushes. Retry once before
            // giving up, but always clear local state so sign-out completes.
            print("PushNotificationManager: unregister failed, retrying: \(error)")
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            try? await convex.removeDeviceToken(token: token)
        }
        deviceToken = nil
        pendingUserId = nil
        isRegistered = false
    }
}
