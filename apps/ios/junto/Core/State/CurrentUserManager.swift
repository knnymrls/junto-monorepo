//
//  CurrentUserManager.swift
//  mkrs-world
//
//  Global state for the current user's user profile.
//  Resolves once in ContentView, available everywhere via @EnvironmentObject.
//

import SwiftUI

@MainActor
class CurrentUserManager: ObservableObject {
    static let shared = CurrentUserManager()

    @Published var user: UserResponse?
    @Published var isLoading = false

    var userId: String? { user?._id }

    private let convex = ConvexClientManager.shared

    func resolve(clerkId: String) async {
        guard user == nil else { return }
        isLoading = true
        do {
            user = try await convex.fetchUserByClerkId(clerkId: clerkId)
            if let m = user {
                AnalyticsService.shared.identify(
                    userId: m._id,
                    properties: [
                        "name": m.name,
                        "is_onboarded": m.isOnboarded
                    ]
                )
            }
        } catch {
            print("CurrentUserManager: Failed to resolve user: \(error)")
        }
        isLoading = false
    }

    func refresh(clerkId: String) async {
        isLoading = true
        do {
            user = try await convex.fetchUserByClerkId(clerkId: clerkId)
        } catch {
            print("CurrentUserManager: Failed to refresh user: \(error)")
        }
        isLoading = false
    }

    func clear() {
        user = nil
    }
}
