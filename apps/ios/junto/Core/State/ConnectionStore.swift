//
//  ConnectionStore.swift
//  mkrs-world
//
//  Single source of truth for the current user's connection state. Replaces
//  the per-ViewModel copies of connectedUserIds/pendingConnectionIds that were
//  kept in sync via NotificationCenter broadcasts — every avatar badge reads
//  (and every connect action writes) here, and live Convex subscriptions keep
//  it true across devices and screens.
//

import SwiftUI
import Combine

@MainActor
final class ConnectionStore: ObservableObject {
    static let shared = ConnectionStore()

    @Published private(set) var connectedUserIds: Set<String> = []
    @Published private(set) var pendingSentIds: Set<String> = []
    /// User-facing failure from a connection action — views alert on it.
    @Published var actionError: String?

    private let convex = ConvexClientManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var subscribedUserId: String?
    private var currentUserId: String? { subscribedUserId }

    private init() {}

    /// Attach the live subscriptions for the signed-in user. Idempotent.
    func start(userId: String) {
        guard subscribedUserId != userId else { return }
        subscribedUserId = userId
        cancellables.removeAll()

        convex.subscribeConnections(userId: userId)
            .resubscribeOnFailure()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] users in
                self?.connectedUserIds = Set(users.map { $0._id })
            }
            .store(in: &cancellables)

        convex.subscribePendingSentIds(userId: userId)
            .resubscribeOnFailure()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ids in
                self?.pendingSentIds = Set(ids)
            }
            .store(in: &cancellables)
    }

    func stop() {
        cancellables.removeAll()
        subscribedUserId = nil
        connectedUserIds = []
        pendingSentIds = []
    }

    // MARK: - Reads

    func isConnected(_ userId: String) -> Bool {
        connectedUserIds.contains(userId)
    }

    func isPending(_ userId: String) -> Bool {
        pendingSentIds.contains(userId)
    }

    func displayStatus(for userId: String) -> ConnectionDisplayStatus {
        if connectedUserIds.contains(userId) { return .connected }
        if pendingSentIds.contains(userId) { return .pending }
        return .none
    }

    // MARK: - Actions (optimistic, with revert + surfaced errors)

    @discardableResult
    func sendRequest(to userId: String, source: ConnectionSource = .feed) async -> Bool {
        guard let myUserId = currentUserId else { return false }
        pendingSentIds.insert(userId)
        do {
            _ = try await convex.sendConnectionRequest(requesterId: myUserId, accepterId: userId)
            AnalyticsService.shared.track(.connectionSent(toUserId: userId, source: source))
            return true
        } catch {
            pendingSentIds.remove(userId)
            actionError = "Couldn't send the connection request. Try again."
            print("ConnectionStore: send request failed: \(error)")
            return false
        }
    }

    @discardableResult
    func withdrawRequest(to userId: String) async -> Bool {
        guard let myUserId = currentUserId else { return false }
        pendingSentIds.remove(userId)
        do {
            _ = try await convex.withdrawConnectionRequest(requesterId: myUserId, accepterId: userId)
            return true
        } catch {
            pendingSentIds.insert(userId)
            actionError = "Couldn't withdraw the request. Try again."
            print("ConnectionStore: withdraw failed: \(error)")
            return false
        }
    }

    @discardableResult
    func removeConnection(with userId: String) async -> Bool {
        guard let myUserId = currentUserId else { return false }
        connectedUserIds.remove(userId)
        do {
            _ = try await convex.removeConnection(userId1: myUserId, userId2: userId)
            return true
        } catch {
            connectedUserIds.insert(userId)
            actionError = "Couldn't remove the connection. Try again."
            print("ConnectionStore: remove failed: \(error)")
            return false
        }
    }

    /// Withdraw a pending request or remove an existing connection, whichever
    /// matches the current state.
    @discardableResult
    func disconnect(from userId: String) async -> Bool {
        switch displayStatus(for: userId) {
        case .connected: return await removeConnection(with: userId)
        case .pending: return await withdrawRequest(to: userId)
        case .none: return false
        }
    }

    @discardableResult
    func acceptRequest(from userId: String) async -> Bool {
        guard let myUserId = currentUserId else { return false }
        connectedUserIds.insert(userId)
        do {
            _ = try await convex.acceptConnectionRequestByUsers(currentUserId: myUserId, otherUserId: userId)
            return true
        } catch {
            connectedUserIds.remove(userId)
            actionError = "Couldn't accept the request. Try again."
            print("ConnectionStore: accept failed: \(error)")
            return false
        }
    }
}
