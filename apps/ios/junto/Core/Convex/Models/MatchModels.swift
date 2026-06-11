//
//  MatchModels.swift
//  mkrs-world
//
//  Suggested match model types (+ preview mocks).
//

import Foundation
import ConvexMobile
import Combine
import UIKit


// MARK: - Suggested Match Response

struct SuggestedMatchResponse: Codable, Identifiable, Hashable {
    let _id: String
    let clerkId: String
    let email: String?
    let name: String
    let headline: String?
    let avatarUrl: String?
    let universityId: String?
    let currentProject: String?
    let lookingFor: String?
    let canHelpWith: String?
    let skills: [String]?
    let interests: [String]?
    let role: String?
    let isOnboarded: Bool
    let createdAt: Double
    let updatedAt: Double
    let matchType: String?
    let matchReason: String

    var id: String { _id }

    func toUserResponse() -> UserResponse {
        UserResponse(
            _id: _id,
            clerkId: clerkId,
            email: email,
            phone: nil,
            name: name,
            headline: headline,
            avatarUrl: avatarUrl,
            universityId: universityId,
            majors: nil,
            graduationSemester: nil,
            programs: nil,
            skills: skills,
            interests: interests,
            lookingFor: lookingFor,
            canHelpWith: canHelpWith,
            currentProject: currentProject,
            socialLinks: nil,
            role: role,
            platformRole: nil,
            status: nil,
            isOnboarded: isOnboarded,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}


// MARK: - Mock Data for Suggested Matches

extension SuggestedMatchResponse {
    static let mock = SuggestedMatchResponse(
        _id: "match_1",
        clerkId: "clerk_match_1",
        email: "sarah@example.com",
        name: "Sarah Chen",
        headline: "Co-founder @ TechStartup",
        avatarUrl: nil,
        universityId: nil,
        currentProject: "DevTools",
        lookingFor: "Designer, marketing help",
        canHelpWith: "Engineering, APIs",
        skills: ["React", "Node.js", "AWS"],
        interests: ["DevTools", "AI"],
        role: "student",
        isOnboarded: true,
        createdAt: Date().timeIntervalSince1970 * 1000,
        updatedAt: Date().timeIntervalSince1970 * 1000,
        matchType: "complementary",
        matchReason: "They're looking for a designer and you got skills"
    )
}
