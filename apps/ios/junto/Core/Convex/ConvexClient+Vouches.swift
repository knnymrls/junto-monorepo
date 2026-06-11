//
//  ConvexClient+Vouches.swift
//  mkrs-world
//
//  Vouches.
//

import Foundation
import ConvexMobile
import Combine
import UIKit

extension ConvexClientManager {

    // MARK: Vouches

    /// Subscribe to vouches received by a user
    func subscribeVouches(userId: String) -> AnyPublisher<[VouchResponse], ClientError> {
        return client.subscribe(to: "vouches:listForUser", with: ["userId": userId], yielding: [VouchResponse].self)
    }
}

extension ConvexClientManager {

    // MARK: Vouches

    /// Create a vouch for someone
    func createVouch(fromUserId: String, toUserId: String, reason: String) async throws -> String {
        return try await client.mutation("vouches:create", with: [
            "fromUserId": fromUserId,
            "toUserId": toUserId,
            "reason": reason
        ])
    }


    /// Fetch vouches for a user
    func fetchVouches(userId: String) async throws -> [VouchResponse] {
        return try await queryOnce("vouches:listForUser", with: ["userId": userId], yielding: [VouchResponse].self)
    }


    /// Check if current user has vouched for someone
    func hasVouched(fromUserId: String, toUserId: String) async throws -> Bool {
        return try await queryOnce("vouches:hasVouched", with: [
                "fromUserId": fromUserId,
                "toUserId": toUserId
            ], yielding: Bool.self)
    }
}
