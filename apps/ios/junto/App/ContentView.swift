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
            #if DEBUG
            // Dev preview bypass: launch with env JUNTO_PREVIEW_FEED=1 to skip auth
            // and land straight on the feed (for previewing feed components on the
            // simulator without signing in). Never compiled into release builds.
            if ProcessInfo.processInfo.environment["JUNTO_PREVIEW_FEED"] == "1" {
                TabBarView()
            } else if clerk.user == nil {
                WelcomeView()
            } else if currentUser.isLoading {
                LoadingView()
            } else if forceOnboarding {
                OnboardingView()
            } else if currentUser.user == nil || !currentUser.user!.isOnboarded {
                OnboardingView()
            } else {
                TabBarView()
            }
            #else
            if clerk.user == nil {
                // Not authenticated
                WelcomeView()
            } else if currentUser.isLoading {
                // Checking if user has profile
                LoadingView()
            } else if currentUser.user == nil || !currentUser.user!.isOnboarded {
                OnboardingView()
            } else {
                TabBarView()
            }
            #endif
        }
        #if DEBUG
        .onAppear {
            // Preview rig: seed a mock user so the feed nav avatar renders.
            if ProcessInfo.processInfo.environment["JUNTO_PREVIEW_FEED"] == "1", currentUser.user == nil {
                currentUser.user = .previewMock
            }
        }
        #endif
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
            VStack(spacing: 20) {
                AnimatedJuntoLogo(size: 88)
                Text("Junto")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.appPrimary)
            }
        }
    }
}

/// The Junto mark with a simple breathing pulse — gently scales in and out.
/// No spin, no fading.
struct AnimatedJuntoLogo: View {
    var size: CGFloat = 88

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    var body: some View {
        Image("junto-logo")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundColor(.appPrimary)
            .scaleEffect(reduceMotion ? 1 : (pulse ? 1.08 : 0.92))
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 0.7).repeatForever(autoreverses: true),
                value: pulse
            )
            .onAppear { pulse = true }
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
