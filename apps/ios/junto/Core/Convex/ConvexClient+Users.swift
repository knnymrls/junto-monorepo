//
//  ConvexClient+Users.swift
//  mkrs-world
//
//  User queries, subscriptions, and profile mutations.
//

import Foundation
import ConvexMobile
import Combine
import UIKit

extension ConvexClientManager {

    // MARK: Users

    /// Subscribe to users list with real-time updates
    func subscribeUsers(universityId: String? = nil, limit: Int? = nil) -> AnyPublisher<[UserResponse], ClientError> {
        var args: [String: (any ConvexEncodable)?] = [:]
        if let universityId = universityId {
            args["universityId"] = universityId
        }
        if let limit = limit {
            args["limit"] = Double(limit)
        }

        if args.isEmpty {
            return client.subscribe(to: "users:list", yielding: [UserResponse].self)
        } else {
            return client.subscribe(to: "users:list", with: args, yielding: [UserResponse].self)
        }
    }


    /// Subscribe to a single user by ID
    func subscribeUser(id: String) -> AnyPublisher<UserResponse?, ClientError> {
        return client.subscribe(to: "users:get", with: ["id": id], yielding: UserResponse?.self)
    }


    /// Subscribe to user by Clerk ID
    func subscribeUserByClerkId(clerkId: String) -> AnyPublisher<UserResponse?, ClientError> {
        return client.subscribe(to: "users:getByClerkId", with: ["clerkId": clerkId], yielding: UserResponse?.self)
    }




}

extension ConvexClientManager {

}

extension ConvexClientManager {

    // MARK: Users

    /// Create or update a user profile
    func upsertUser(_ user: UserInput) async throws -> String {
        return try await client.mutation("users:upsert", with: user.toArgs())
    }
}

extension ConvexClientManager {

    /// Fetch users once (takes first value from subscription)
    func fetchUsers(universityId: String? = nil, limit: Int? = nil) async throws -> [UserResponse] {
        return try await queryOnce(subscribeUsers(universityId: universityId, limit: limit))
    }


    /// Fetch a single user by ID once
    func fetchUser(id: String) async throws -> UserResponse? {
        return try await queryOnce(subscribeUser(id: id))
    }


    /// Fetch the profile display context (university + major/skill names) once
    func fetchProfileContext(userId: String) async throws -> ProfileContextResponse? {
        return try await queryOnce("users:getProfileContext", with: ["userId": userId], yielding: ProfileContextResponse?.self)
    }


    /// Fetch user by Clerk ID once
    func fetchUserByClerkId(clerkId: String) async throws -> UserResponse? {
        return try await queryOnce(subscribeUserByClerkId(clerkId: clerkId))
    }


    /// Fetch user by name (for mentions)
    func fetchUserByName(name: String) async throws -> UserResponse? {
        return try await queryOnce("users:getByName", with: ["name": name], yielding: UserResponse?.self)
    }
}
