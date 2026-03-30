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
            .onOpenURL { url in
                handleIncomingURL(url)
            }
        }
    }

    /// Parse invite codes from incoming URLs.
    /// Supports:
    ///   - Custom scheme: junto://join/CODE
    ///   - Universal link: https://onjunto.com/join/CODE
    private func handleIncomingURL(_ url: URL) {
        let code: String?

        if url.scheme == "junto" {
            // junto://join/CODE
            // host = "join", path components = ["", "CODE"]
            if url.host == "join" {
                let pathCode = url.pathComponents.dropFirst().first
                code = pathCode
            } else {
                code = nil
            }
        } else {
            // Universal link: https://onjunto.com/join/CODE
            let components = url.pathComponents
            if components.count >= 3, components[1] == "join" {
                code = components[2]
            } else {
                code = nil
            }
        }

        guard let code, !code.isEmpty else { return }

        AnalyticsService.shared.track(.inviteLinkOpened(code: code))

        // Persist the invite code so it survives the auth flow
        // (user may not be signed in yet when the link is opened)
        UserDefaults.standard.set(code, forKey: "pendingInviteCode")

        // Also post notification for immediate pickup if onboarding is already visible
        NotificationCenter.default.post(
            name: .inviteLinkReceived,
            object: nil,
            userInfo: ["code": code]
        )
    }
}
