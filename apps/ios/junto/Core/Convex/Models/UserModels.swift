//
//  UserModels.swift
//  mkrs-world
//
//  User, profile, and connection model types (+ preview mocks).
//

import Foundation
import ConvexMobile
import Combine
import UIKit


// MARK: - Connection Status

enum ConnectionStatus: String {
    case none = "none"
    case pendingSent = "pending_sent"
    case pendingReceived = "pending_received"
    case connected = "connected"
}


// MARK: - Connection Events

extension Notification.Name {
    /// Broadcast whenever the current user's connection status with someone
    /// changes (request sent / accepted / withdrawn / removed). Lets every
    /// surface that caches connection state (feed, search, attendees) update
    /// its avatar badges immediately instead of waiting for the next reload.
    static let connectionStatusChanged = Notification.Name("connectionStatusChanged")
}


// MARK: - Response Types

struct UserMajorResponse: Codable, Hashable {
    let majorId: String
    let credentialLevel: Double
}


struct UserResponse: Codable, Identifiable, Hashable {
    let _id: String
    let clerkId: String
    let email: String?
    let phone: String?
    let name: String
    let headline: String?
    let avatarUrl: String?
    let universityId: String?
    let majors: [UserMajorResponse]?
    let graduationSemester: String?
    let programs: [String]?
    let skills: [String]?
    var skillCategories: [String]? = nil
    let interests: [String]?
    let lookingFor: String?
    let canHelpWith: String?
    let currentProject: String?
    let socialLinks: SocialLinksResponse?
    let role: String?
    let platformRole: String?
    let status: String?
    let isOnboarded: Bool
    let createdAt: Double
    let updatedAt: Double

    var id: String { _id }

    struct SocialLinksResponse: Codable, Hashable {
        let linkedin: String?
        let instagram: String?
        let twitter: String?
        let github: String?
        let website: String?
    }
}


// MARK: - Profile Context Response

/// Display names for the reference IDs on a user (users:getProfileContext).
struct ProfileContextResponse: Codable, Hashable {
    let university: University?
    let majorNames: [String]
    let skillNames: [String]

    struct University: Codable, Hashable {
        let name: String
        let shortName: String?
        let logoUrl: String?
    }
}


// MARK: - Mock Data for Previews

extension UserResponse {
    static let mock = UserResponse(
        _id: "mock_1",
        clerkId: "clerk_mock_1",
        email: "kenny@onjunto.com",
        phone: nil,
        name: "Kenny Morales",
        headline: "Building FindU - College decision platform",
        avatarUrl: nil,
        universityId: nil,
        majors: nil,
        graduationSemester: "Spring 2027",
        programs: nil,
        skills: ["Swift", "iOS", "Product"],
        interests: ["EdTech", "AI", "Mobile"],
        lookingFor: "Technical co-founder, iOS developers",
        canHelpWith: "Startup strategy, pitch decks",
        currentProject: "FindU",
        socialLinks: SocialLinksResponse(
            linkedin: "https://linkedin.com/in/kennymorales",
            instagram: nil,
            twitter: "https://twitter.com/knnymrls",
            github: "https://github.com/knnymrls",
            website: "https://onjunto.com"
        ),
        role: "student",
        platformRole: "superadmin",
        status: "active",
        isOnboarded: true,
        createdAt: Date().timeIntervalSince1970 * 1000,
        updatedAt: Date().timeIntervalSince1970 * 1000
    )

    #if DEBUG
    /// Preview-only user with a real avatar, for the JUNTO_PREVIEW_FEED rig.
    static let previewMock = UserResponse(
        _id: "mock_1",
        clerkId: "clerk_mock_1",
        email: "kenny@onjunto.com",
        phone: nil,
        name: "Kenny Morales",
        headline: "Building FindU",
        avatarUrl: "https://i.pravatar.cc/300?img=13",
        universityId: nil,
        majors: nil,
        graduationSemester: "Spring 2027",
        programs: nil,
        skills: ["Swift", "iOS", "Product"],
        interests: ["EdTech", "AI"],
        lookingFor: "Technical co-founder",
        canHelpWith: "Startup strategy",
        currentProject: "FindU",
        socialLinks: nil,
        role: "student",
        platformRole: "superadmin",
        status: "active",
        isOnboarded: true,
        createdAt: Date().timeIntervalSince1970 * 1000,
        updatedAt: Date().timeIntervalSince1970 * 1000
    )
    #endif

    static let mockList: [UserResponse] = [
        mock,
        UserResponse(
            _id: "mock_2",
            clerkId: "clerk_mock_2",
            email: "sarah@example.com",
            phone: nil,
            name: "Sarah Chen",
            headline: "Full-stack developer | React & Node",
            avatarUrl: nil,
            universityId: nil,
            majors: nil,
            graduationSemester: nil,
            programs: nil,
            skills: ["React", "TypeScript", "Node.js"],
            interests: ["FoodTech", "AI"],
            lookingFor: "Co-founder with marketing skills",
            canHelpWith: "Frontend, API design",
            currentProject: "AI recipe generator",
            socialLinks: nil,
            role: "student",
            platformRole: nil,
            status: nil,
            isOnboarded: true,
            createdAt: Date().timeIntervalSince1970 * 1000,
            updatedAt: Date().timeIntervalSince1970 * 1000
        ),
        UserResponse(
            _id: "mock_3",
            clerkId: "clerk_mock_3",
            email: "marcus@example.com",
            phone: nil,
            name: "Marcus Williams",
            headline: "UX Designer | Previously at Google",
            avatarUrl: nil,
            universityId: nil,
            majors: nil,
            graduationSemester: nil,
            programs: nil,
            skills: ["Figma", "Design Systems"],
            interests: ["DesignOps", "Mobile"],
            lookingFor: "Developers to collaborate with",
            canHelpWith: "UI/UX design",
            currentProject: "Design system for startups",
            socialLinks: nil,
            role: "student",
            platformRole: nil,
            status: nil,
            isOnboarded: true,
            createdAt: Date().timeIntervalSince1970 * 1000,
            updatedAt: Date().timeIntervalSince1970 * 1000
        )
    ]
}


// MARK: - Input Types

struct MajorInput {
    let majorId: String
    let credentialLevel: Int
}


struct UserInput {
    let clerkId: String
    var email: String?
    var phone: String?
    let name: String
    var headline: String?
    var avatarUrl: String?
    var universityId: String?
    var majors: [MajorInput]?
    var graduationSemester: String?
    var programs: [String]?
    var skills: [String]?
    var interests: [String]?
    var lookingFor: String?
    var canHelpWith: String?
    var currentProject: String?
    var socialLinks: SocialLinksInput?
    var role: String?
    var platformRole: String?

    struct SocialLinksInput {
        var linkedin: String?
        var instagram: String?
        var twitter: String?
        var github: String?
        var website: String?
    }

    func toArgs() -> [String: (any ConvexEncodable)?] {
        var args: [String: (any ConvexEncodable)?] = [
            "clerkId": clerkId,
            "name": name
        ]
        if let email = email { args["email"] = email }
        if let phone = phone { args["phone"] = phone }
        if let headline = headline { args["headline"] = headline }
        if let avatarUrl = avatarUrl { args["avatarUrl"] = avatarUrl }
        if let universityId = universityId { args["universityId"] = universityId }
        if let graduationSemester = graduationSemester { args["graduationSemester"] = graduationSemester }
        if let currentProject = currentProject { args["currentProject"] = currentProject }
        if let lookingFor = lookingFor { args["lookingFor"] = lookingFor }
        if let canHelpWith = canHelpWith { args["canHelpWith"] = canHelpWith }
        if let role = role { args["role"] = role }
        if let platformRole = platformRole { args["platformRole"] = platformRole }
        if let skills = skills {
            let arr: [ConvexEncodable?] = skills.map { $0 as ConvexEncodable? }
            args["skills"] = arr
        }
        if let interests = interests {
            let arr: [ConvexEncodable?] = interests.map { $0 as ConvexEncodable? }
            args["interests"] = arr
        }
        if let programs = programs {
            let arr: [ConvexEncodable?] = programs.map { $0 as ConvexEncodable? }
            args["programs"] = arr
        }
        if let majors = majors {
            let arr: [ConvexEncodable?] = majors.map { major in
                [
                    "majorId": major.majorId as ConvexEncodable?,
                    "credentialLevel": Double(major.credentialLevel) as ConvexEncodable?
                ] as ConvexEncodable?
            }
            args["majors"] = arr
        }
        if let socialLinks = socialLinks {
            var links: [String: ConvexEncodable?] = [:]
            if let linkedin = socialLinks.linkedin { links["linkedin"] = linkedin }
            if let instagram = socialLinks.instagram { links["instagram"] = instagram }
            if let twitter = socialLinks.twitter { links["twitter"] = twitter }
            if let github = socialLinks.github { links["github"] = github }
            if let website = socialLinks.website { links["website"] = website }
            args["socialLinks"] = links as ConvexEncodable?
        }
        return args
    }
}
