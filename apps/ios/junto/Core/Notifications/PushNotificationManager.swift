//
//  PushNotificationManager.swift
//  mkrs-world
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
    private let convex = ConvexClientManager.shared

    func requestPermission() {
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
    }

    func registerWithBackend(userId: String) async {
        guard let token = deviceToken else { return }
        let device = UIDevice.current
        try? await convex.registerDeviceToken(
            userId: userId,
            token: token,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            deviceModel: device.model,
            osVersion: device.systemVersion
        )
    }

    func unregister() async {
        guard let token = deviceToken else { return }
        try? await convex.removeDeviceToken(token: token)
        deviceToken = nil
        isRegistered = false
    }
}
