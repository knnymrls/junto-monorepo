//
//  mkrsWorldApp.swift
//  mkrs-world
//
//  Entry point for the onjunto.com iOS app
//

import SwiftUI
import Clerk
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task { @MainActor in
            PushNotificationManager.shared.handleToken(deviceToken)
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("APNs registration failed: \(error)")
    }
}

@main
struct juntoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var currentUser = CurrentUserManager.shared
    @State private var clerk = Clerk.shared

    var body: some Scene {
        WindowGroup {
            ImageViewerRoot {
                ContentView()
                    .environment(\.clerk, clerk)
                    .environmentObject(themeManager)
                    .environmentObject(currentUser)
                    .preferredColorScheme(themeManager.selectedAppearance.colorScheme)
                    .task {
                        clerk.configure(publishableKey: "pk_live_Y2xlcmsub25qdW50by5jb20k")
                        try? await clerk.load()

                        // Initialize analytics after Clerk loads
                        AnalyticsService.shared.configure()

                        // Clear old cached images (>7 days)
                        ImageCache.shared.clearOldEntries()
                    }
            }
        }
    }
}
