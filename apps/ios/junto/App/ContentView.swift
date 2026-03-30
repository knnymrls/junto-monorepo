//
//  ContentView.swift
//  mkrs-world
//
//  Root view that handles auth state via Clerk
//

import SwiftUI
import Clerk

// Notification for when onboarding completes
extension Notification.Name {
    static let onboardingComplete = Notification.Name("onboardingComplete")
    static let inviteLinkReceived = Notification.Name("inviteLinkReceived")
}

struct ContentView: View {
    @Environment(\.clerk) private var clerk
    @EnvironmentObject private var currentUser: CurrentUserManager
    #if DEBUG
    @State private var forceOnboarding = false
    #endif

    var body: some View {
        Group {
            if clerk.user == nil {
                // Not authenticated
                WelcomeView()
            } else if currentUser.isLoading {
                // Checking if user has profile
                LoadingView()
            } else {
                #if DEBUG
                if forceOnboarding {
                    OnboardingView()
                } else if currentUser.user == nil || !currentUser.user!.isOnboarded {
                    OnboardingView()
                } else {
                    TabBarView()
                }
                #else
                if currentUser.user == nil || !currentUser.user!.isOnboarded {
                    OnboardingView()
                } else {
                    TabBarView()
                }
                #endif
            }
        }
        .onChange(of: clerk.user?.id) { _, newUserId in
            if let userId = newUserId {
                Task { await currentUser.resolve(clerkId: userId) }
            } else {
                Task { await PushNotificationManager.shared.unregister() }
                currentUser.clear()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .onboardingComplete)) { _ in
            #if DEBUG
            forceOnboarding = false
            #endif
            if let userId = clerk.user?.id {
                Task { await currentUser.refresh(clerkId: userId) }
            }
        }
        .task {
            if let userId = clerk.user?.id {
                await currentUser.resolve(clerkId: userId)
            }
        }
        .onChange(of: currentUser.user?._id) { _, newUserId in
            if let userId = newUserId {
                PushNotificationManager.shared.requestPermissionAndRegister(userId: userId)
            }
        }
        .task {
            // Also register on app launch if already signed in
            if let userId = currentUser.user?._id {
                PushNotificationManager.shared.requestPermissionAndRegister(userId: userId)
            }
        }
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Junto")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.appPrimary)
                ProgressView()
                    .tint(.appPrimary)
            }
        }
    }
}

#Preview("Main App") {
    ContentView()
        .environmentObject(ThemeManager.shared)
        .environmentObject(CurrentUserManager.shared)
}

#Preview("Welcome") {
    WelcomeView()
}

#Preview("Onboarding") {
    OnboardingView()
}
