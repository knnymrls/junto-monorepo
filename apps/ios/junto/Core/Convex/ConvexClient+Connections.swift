//
//  ConvexClient+Connections.swift
//  mkrs-world
//
//  Connection requests, status, and lifecycle.
//

import Foundation
import ConvexMobile
import Combine
import UIKit

extension ConvexClientManager {

    // MARK: Connections

    /// Subscribe to connections for a user
    func subscribeConnections(userId: String) -> AnyPublisher<[UserResponse], ClientError> {
        return client.subscribe(to: "connections:listForUser", with: ["userId": userId], yielding: [UserResponse].self)
    }
}

extension ConvexClientManager {

    // MARK: Connections

    /// Create a connection between two users (instant - for MVP)
    func connect(requesterId: String, accepterId: String) async throws -> String {
        return try await client.mutation("connections:connect", with: [
            "requesterId": requesterId,
            "accepterId": accepterId
        ])
    }


    /// Send a connection request (creates pending connection)
    func sendConnectionRequest(requesterId: String, accepterId: String) async throws -> String {
        return try await client.mutation("connections:sendRequest", with: [
            "requesterId": requesterId,
            "accepterId": accepterId
        ])
    }


    /// Accept a connection request
    func acceptConnectionRequest(connectionId: String) async throws -> String {
        return try await client.mutation("connections:acceptRequest", with: [
            "connectionId": connectionId
        ])
    }


    func rejectConnectionRequest(connectionId: String) async throws -> String {
        return try await client.mutation("connections:rejectRequest", with: [
            "connectionId": connectionId
        ])
    }


    func withdrawConnectionRequest(requesterId: String, accepterId: String) async throws -> String {
        return try await client.mutation("connections:withdrawRequest", with: [
            "requesterId": requesterId,
            "accepterId": accepterId
        ])
    }


    func removeConnection(userId1: String, userId2: String) async throws -> String {
        return try await client.mutation("connections:removeConnection", with: [
            "userId1": userId1,
            "userId2": userId2
        ])
    }


    func acceptConnectionRequestByUsers(currentUserId: String, otherUserId: String) async throws -> String {
        return try await client.mutation("connections:acceptRequestByUsers", with: [
            "currentUserId": currentUserId,
            "otherUserId": otherUserId
        ])
    }
}

extension ConvexClientManager {

    /// Check if two users are connected
    func checkConnection(userId1: String, userId2: String) async throws -> Bool {
        return try await queryOnce("connections:checkConnection", with: [
                "userId1": userId1,
                "userId2": userId2
            ], yielding: Bool.self)
    }


    // MARK: Connections

    /// Fetch connections for a user once
    func fetchConnections(userId: String) async throws -> [UserResponse] {
        return try await queryOnce(subscribeConnections(userId: userId))
    }


    /// Get connection status between two users
    func getConnectionStatus(fromUserId: String, toUserId: String) async throws -> ConnectionStatus {
        let status = try await queryOnce("connections:getConnectionStatus", with: [
            "fromUserId": fromUserId,
            "toUserId": toUserId
        ], yielding: String.self)
        return ConnectionStatus(rawValue: status) ?? .none
    }


    /// Fetch IDs of users I've sent pending requests to
    func fetchPendingSentIds(userId: String) async throws -> [String] {
        return try await queryOnce("connections:listPendingSentIds", with: [
                "userId": userId
            ], yielding: [String].self)
    }
}
