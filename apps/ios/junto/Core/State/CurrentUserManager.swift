//
//  CurrentUserManager.swift
//  mkrs-world
//
//  Global state for the current user's profile. Resolved once in ContentView,
//  then kept live via a Convex subscription — profile edits, avatar changes,
//  and backend updates propagate everywhere automatically.
//

import SwiftUI
import Combine

@MainActor
class CurrentUserManager: ObservableObject {
    static let shared = CurrentUserManager()

    @Published var user: UserResponse?
    @Published var isLoading = false
    /// Set when the initial resolve fails. Distinguishes "fetch failed" from
    /// "signed in but no profile yet" — routing must NOT send an existing user
    /// into onboarding just because one launch request flaked.
    @Published var loadFailed = false

    var userId: String? { user?._id }

    private let convex = ConvexClientManager.shared
    private var subscription: AnyCancellable?
    private var subscribedClerkId: String?

    /// Resolve the user once, then keep the profile live. Safe to call
    /// repeatedly (e.g. retry after a failure) — it re-subscribes only when
    /// the Clerk identity changes or the last attempt failed.
    func resolve(clerkId: String) async {
        if subscribedClerkId == clerkId, user != nil || isLoading { return }
        isLoading = true
        loadFailed = false
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
            subscribe(clerkId: clerkId)
        } catch {
            loadFailed = true
            print("CurrentUserManager: Failed to resolve user: \(error)")
        }
        isLoading = false
    }

    /// Force a one-shot refresh (e.g. right after onboarding completes).
    func refresh(clerkId: String) async {
        isLoading = true
        do {
            user = try await convex.fetchUserByClerkId(clerkId: clerkId)
            loadFailed = false
            subscribe(clerkId: clerkId)
        } catch {
            // Keep any existing user; a failed refresh isn't a sign-out.
            if user == nil { loadFailed = true }
            print("CurrentUserManager: Failed to refresh user: \(error)")
        }
        isLoading = false
    }

    /// Live subscription: any change to the user row (avatar, headline,
    /// onboarding state) lands here without manual refresh calls.
    private func subscribe(clerkId: String) {
        guard subscribedClerkId != clerkId || subscription == nil else { return }
        subscribedClerkId = clerkId
        subscription = convex.subscribeUserByClerkId(clerkId: clerkId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    // A failed subscription shouldn't wipe state; next
                    // resolve() reattaches.
                    if case .failure(let error) = completion {
                        print("CurrentUserManager: user subscription ended: \(error)")
                        self?.subscription = nil
                        self?.subscribedClerkId = nil
                    }
                },
                receiveValue: { [weak self] fresh in
                    guard let self, let fresh else { return }
                    self.user = fresh
                }
            )
    }

    func clear() {
        subscription?.cancel()
        subscription = nil
        subscribedClerkId = nil
        user = nil
        loadFailed = false
    }
}
