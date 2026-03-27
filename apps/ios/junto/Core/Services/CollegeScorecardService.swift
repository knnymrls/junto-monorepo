//
//  CollegeScorecardService.swift
//  junto
//
//  Fetches programs/majors per university from the College Scorecard API
//  (US Dept of Education). Zero Convex bandwidth cost.
//

import Foundation

// MARK: - Response Models

struct ScorecardResponse: Codable {
    let results: [ScorecardSchool]
}

struct ScorecardSchool: Codable {
    let id: Int
    let schoolName: String?
    let programs: [ScorecardProgram]?

    enum CodingKeys: String, CodingKey {
        case id
        case schoolName = "school.name"
        case programs = "latest.programs.cip_4_digit"
    }
}

struct ScorecardProgram: Codable {
    let code: String
    let title: String
    let credential: ScorecardCredential
}

struct ScorecardCredential: Codable {
    let level: Int
    let title: String
}

// MARK: - Clean Major (what we display)

struct MajorOption: Identifiable, Hashable {
    let cipCode: String
    let name: String
    let credentialLevel: Int
    let credentialTitle: String
    var category: String = ""
    var convexId: String?  // Convex document ID from majors table

    var id: String { "\(convexId ?? cipCode)_\(credentialLevel)" }

    var displayName: String {
        let prefix: String
        switch credentialLevel {
        case 1: prefix = "Certificate in"
        case 2: prefix = "Associate's in"
        case 3: prefix = "BS in"
        case 4: prefix = "Post-Bacc in"
        case 5: prefix = "MS in"
        case 6: prefix = "PhD in"
        case 7: prefix = "Professional in"
        case 8: prefix = "Grad Certificate in"
        default: return name
        }
        return "\(prefix) \(name)"
    }
}

// MARK: - Service

@MainActor
class CollegeScorecardService {
    static let shared = CollegeScorecardService()

    // DEMO_KEY works for testing (30 req/hr). Replace with real key for production.
    private let apiKey = "DEMO_KEY"
    private let baseURL = "https://api.data.gov/ed/collegescorecard/v1/schools"

    // In-memory cache keyed by university name
    private var cache: [String: [MajorOption]] = [:]

    func fetchMajors(universityName: String) async throws -> [MajorOption] {
        // Check cache first
        if let cached = cache[universityName] {
            return cached
        }

        // Build URL
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "school.name", value: universityName),
            URLQueryItem(name: "fields", value: "id,school.name,latest.programs.cip_4_digit"),
            URLQueryItem(name: "per_page", value: "1"),
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ScorecardResponse.self, from: data)

        guard let school = response.results.first,
              let programs = school.programs else {
            return []
        }

        // Convert to clean MajorOptions
        var seen = Set<String>()
        var options: [MajorOption] = []

        for program in programs {
            // Use CIP mapping from Supabase first, fall back to basic cleanup
            let name = CIPCodeMapping.cleanName(for: program.code, fallback: cleanName(program.title))
            let option = MajorOption(
                cipCode: program.code,
                name: name,
                credentialLevel: program.credential.level,
                credentialTitle: program.credential.title
            )

            // Deduplicate by id (same CIP + credential level)
            if seen.insert(option.id).inserted {
                options.append(option)
            }
        }

        options.sort { $0.displayName < $1.displayName }

        // Cache
        cache[universityName] = options

        return options
    }

    // MARK: - Name Cleanup

    private func cleanName(_ raw: String) -> String {
        var name = raw

        // Remove trailing period
        if name.hasSuffix(".") {
            name = String(name.dropLast())
        }

        // Remove common generic suffixes
        let suffixes = [
            ", General",
            ", Other",
            ", Not Elsewhere Classified",
            " and Related Services",
            " and Related Programs",
            " and Related Fields",
            "/Related Programs",
        ]
        for suffix in suffixes {
            if name.hasSuffix(suffix) {
                name = String(name.dropLast(suffix.count))
            }
        }

        // Common verbose → clean name mappings
        let renames: [String: String] = [
            "Computer and Information Sciences": "Computer Science",
            "Computer and Information Systems Security/Information Assurance": "Cybersecurity",
            "Electrical and Electronics Engineering": "Electrical Engineering",
            "Mechanical Engineering/Mechanical Technology": "Mechanical Engineering",
            "Business Administration and Management": "Business Administration",
            "Business/Commerce": "Business",
            "Registered Nursing/Registered Nurse": "Nursing",
            "Biology/Biological Sciences": "Biology",
            "Mathematics": "Mathematics",
            "English Language and Literature": "English",
            "Psychology": "Psychology",
            "Political Science and Government": "Political Science",
            "Economics": "Economics",
            "History": "History",
            "Sociology": "Sociology",
            "Philosophy": "Philosophy",
            "Chemistry": "Chemistry",
            "Physics": "Physics",
            "Music": "Music",
            "Fine/Studio Arts": "Fine Arts",
            "Communication and Media Studies": "Communications",
            "Journalism": "Journalism",
            "Marketing/Marketing Management": "Marketing",
            "Finance": "Finance",
            "Accounting": "Accounting",
            "Management Information Systems": "Management Information Systems",
            "Computer Engineering": "Computer Engineering",
            "Civil Engineering": "Civil Engineering",
            "Chemical Engineering": "Chemical Engineering",
            "Biomedical/Medical Engineering": "Biomedical Engineering",
            "Aerospace, Aeronautical and Astronautical/Space Engineering": "Aerospace Engineering",
            "Industrial Engineering": "Industrial Engineering",
            "Environmental/Environmental Health Engineering": "Environmental Engineering",
            "Agricultural/Biological Engineering and Bioengineering": "Agricultural Engineering",
        ]

        if let clean = renames[name] {
            name = clean
        }

        return name.trimmingCharacters(in: .whitespaces)
    }
}
