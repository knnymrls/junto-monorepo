//
//  OnboardingService.swift
//  junto
//
//  Convex queries for onboarding flow
//

import Foundation
import ConvexMobile
import Combine

// MARK: - Response Types

struct UniversityResult: Codable, Identifiable, Hashable {
    let _id: String
    let name: String
    let shortName: String?
    let city: String
    let state: String
    let logoUrl: String?

    var id: String { _id }
}

struct MajorResult: Codable, Identifiable, Hashable {
    let _id: String
    let name: String
    let category: String
    let cipCode: String?
    let credentialLevel: Double?
    let credentialTitle: String?

    var id: String { "\(_id)_\(credentialLevel ?? 0)" }

    var displayName: String {
        guard let level = credentialLevel else { return name }
        let prefix: String
        switch Int(level) {
        case 1: prefix = "Certificate in"
        case 2: prefix = "Associate's in"
        case 3: prefix = "BS in"
        case 5: prefix = "MS in"
        case 6: prefix = "PhD in"
        default: return name
        }
        return "\(prefix) \(name)"
    }
}

struct SkillResult: Codable, Identifiable, Hashable {
    let _id: String
    let name: String
    let category: String

    var id: String { _id }
}

struct InterestResult: Codable, Identifiable, Hashable {
    let _id: String
    let name: String
    let category: String

    var id: String { _id }
}

struct SuggestedConnection: Codable, Identifiable {
    let _id: String
    let name: String
    let headline: String
    let avatarUrl: String?
    let lookingFor: String
    let score: Int

    var id: String { _id }
}

struct SkillsResponse: Codable {
    let suggested: [SkillResult]
    let byCategory: [String: [SkillResult]]
}

struct InterestsResponse: Codable {
    let suggested: [InterestResult]
    let byCategory: [String: [InterestResult]]
}

// MARK: - OnboardingService

@MainActor
class OnboardingService {

    // MARK: - Shared

    static let shared = OnboardingService()

    private let client: ConvexClient

    private init() {
        client = ConvexClientManager.shared.client
    }

    /// Generic helper that wraps `client.subscribe` + Combine into a single async call.
    /// Eliminates repeated `withCheckedThrowingContinuation` / `sink` / `cancellable` boilerplate.
    private func query<T: Decodable>(
        _ functionName: String,
        args: [String: (any ConvexEncodable)?] = [:]
    ) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = client.subscribe(
                to: functionName,
                with: args,
                yielding: T.self
            )
            .first()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                },
                receiveValue: { result in
                    continuation.resume(returning: result)
                }
            )
        }
    }

    // MARK: - Universities

    func searchUniversities(query: String, limit: Double = 10) async throws -> [UniversityResult] {
        try await self.query(
            "onboarding:searchUniversities",
            args: ["query": query, "limit": limit]
        )
    }

    // MARK: - Academics

    func getMajorsForUniversity(universityId: String) async throws -> [String: [MajorResult]] {
        try await query(
            "onboarding:getMajorsForUniversity",
            args: ["universityId": universityId]
        )
    }

    func cacheMajorsForUniversity(universityId: String, programs: [[String: Any]]) async throws {
        let encodablePrograms: [ConvexEncodable?] = programs.map { p in
            [
                "cipCode": p["cipCode"] as! String,
                "name": p["name"] as! String,
                "credentialLevel": p["credentialLevel"] as! Double,
                "credentialTitle": p["credentialTitle"] as! String,
            ] as [String: (any ConvexEncodable)?] as ConvexEncodable?
        }
        let _: [String: Int]? = try await client.mutation(
            "majorCache:cacheMajorsForUniversity",
            with: ["universityId": universityId, "programs": encodablePrograms]
        )
    }

    func getProgramsForUniversity(universityId: String) async throws -> [String] {
        try await query(
            "onboarding:getProgramsForUniversity",
            args: ["universityId": universityId]
        )
    }

    func getSkills(majorCategory: String? = nil) async throws -> SkillsResponse {
        var args: [String: (any ConvexEncodable)?] = [:]
        if let majorCategory { args["majorCategory"] = majorCategory }
        return try await query("onboarding:getSkills", args: args)
    }

    func getInterests(majorCategory: String? = nil) async throws -> InterestsResponse {
        var args: [String: (any ConvexEncodable)?] = [:]
        if let majorCategory { args["majorCategory"] = majorCategory }
        return try await query("onboarding:getInterests", args: args)
    }

    // MARK: - Connections

    func getSuggestedConnections(
        universityId: String,
        excludeClerkId: String,
        skills: [String],
        interests: [String],
        programs: [String],
        graduationSemester: String?
    ) async throws -> [SuggestedConnection] {
        var args: [String: (any ConvexEncodable)?] = [
            "universityId": universityId,
            "excludeClerkId": excludeClerkId,
            "skills": skills as [ConvexEncodable?],
            "interests": interests as [ConvexEncodable?],
            "programs": programs as [ConvexEncodable?],
        ]
        if let semester = graduationSemester {
            args["graduationSemester"] = semester
        }
        return try await query("onboarding:getSuggestedConnections", args: args)
    }
}
