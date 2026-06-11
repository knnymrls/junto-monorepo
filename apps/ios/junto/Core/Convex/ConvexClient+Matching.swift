//
//  ConvexClient+Matching.swift
//  mkrs-world
//
//  Weekly suggested matches.
//

import Foundation
import ConvexMobile
import Combine
import UIKit

extension ConvexClientManager {

    // MARK: Suggested Matches

    /// Fetch this week's pre-computed matches (query, not action — instant)
    func fetchSuggestedMatchesQuery(userId: String) async throws -> [SuggestedMatchResponse] {
        return try await queryOnce("weeklyMatches:getWeeklyMatches", with: ["userId": userId], yielding: [SuggestedMatchResponse].self)
    }


    /// Trigger on-demand match generation for a user (first-open fallback)
    func generateWeeklyMatchesAction(userId: String) async throws {
        let _: String? = try await client.action("weeklyMatches:generateForCurrentUser", with: ["userId": userId])
    }
}

extension ConvexClientManager {

    // MARK: Suggested Matches

    /// Fetch suggested matches once (reads pre-computed weekly matches)
    func fetchSuggestedMatches(userId: String) async throws -> [SuggestedMatchResponse] {
        return try await fetchSuggestedMatchesQuery(userId: userId)
    }
}
