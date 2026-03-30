//
//  OnboardingViewModel.swift
//  junto
//
//  Manages onboarding flow state and persistence
//

import Foundation
import Clerk
import SwiftUI

// MARK: - Persisted State

/// Single Codable struct for all onboarding progress — replaces 13 individual UserDefaults keys.
private struct PersistedState: Codable {
    var step: Int = 0
    var universityId: String = ""
    var universityName: String = ""
    var displayName: String = ""
    var headline: String = ""
    var majorIds: [String] = []
    var gradSemester: String = ""
    var programs: [String] = []
    var skillIds: [String] = []
    var interestIds: [String] = []
    var lookingFor: [String] = []

    private static let key = "onboardingState"

    /// Version key to track schema changes (e.g. removing edu steps)
    private static let versionKey = "onboardingStateVersion"
    private static let currentVersion = 2 // v2: removed edu email steps 1 & 2

    static func load() -> PersistedState {
        // Try new single-key format first
        if let data = UserDefaults.standard.data(forKey: key),
           var state = try? JSONDecoder().decode(PersistedState.self, from: data) {
            // Migrate step numbers if saved before edu steps were removed
            if UserDefaults.standard.integer(forKey: versionKey) < currentVersion {
                if state.step >= 3 {
                    state.step -= 2 // old steps 3-11 → new steps 1-9
                } else if state.step >= 1 {
                    state.step = 1 // was on edu email/verify → go to profile setup
                }
                UserDefaults.standard.set(currentVersion, forKey: versionKey)
                state.save()
            }
            return state
        }
        // Migrate from legacy @AppStorage keys (one-time)
        return migrateLegacyKeys()
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.key)
        UserDefaults.standard.set(Self.currentVersion, forKey: Self.versionKey)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.removeObject(forKey: versionKey)
        // Also clear legacy keys in case they exist
        let legacyKeys = [
            "onboardingStep", "onboardingUniversityId", "onboardingUniversityName",
            "onboardingEduEmail", "onboardingDisplayName", "onboardingHeadline",
            "onboardingMajorIds", "onboardingGradSemester", "onboardingPrograms",
            "onboardingSkillIds", "onboardingInterestIds",
            "onboardingLookingFor", "onboardingCanHelp",
        ]
        for key in legacyKeys { UserDefaults.standard.removeObject(forKey: key) }
    }

    /// One-time migration from the old 13 individual @AppStorage keys.
    private static func migrateLegacyKeys() -> PersistedState {
        let ud = UserDefaults.standard
        let step = ud.integer(forKey: "onboardingStep")
        guard step > 0 else { return PersistedState() }

        let majorStr = ud.string(forKey: "onboardingMajorIds") ?? ""
        let programStr = ud.string(forKey: "onboardingPrograms") ?? ""
        let skillStr = ud.string(forKey: "onboardingSkillIds") ?? ""
        let interestStr = ud.string(forKey: "onboardingInterestIds") ?? ""

        // Remap step numbers: old steps 1-2 (edu) removed, 3+ shift down by 2
        let remappedStep: Int
        if step >= 3 {
            remappedStep = step - 2
        } else if step >= 1 {
            remappedStep = 1 // edu steps → profile setup
        } else {
            remappedStep = step
        }

        let state = PersistedState(
            step: remappedStep,
            universityId: ud.string(forKey: "onboardingUniversityId") ?? "",
            universityName: ud.string(forKey: "onboardingUniversityName") ?? "",
            displayName: ud.string(forKey: "onboardingDisplayName") ?? "",
            headline: ud.string(forKey: "onboardingHeadline") ?? "",
            majorIds: majorStr.isEmpty ? [] : majorStr.components(separatedBy: ","),
            gradSemester: ud.string(forKey: "onboardingGradSemester") ?? "",
            programs: programStr.isEmpty ? [] : programStr.components(separatedBy: "|||"),
            skillIds: skillStr.isEmpty ? [] : skillStr.components(separatedBy: ","),
            interestIds: interestStr.isEmpty ? [] : interestStr.components(separatedBy: ","),
            lookingFor: {
                let str = ud.string(forKey: "onboardingLookingFor") ?? ""
                return str.isEmpty ? [] : str.components(separatedBy: ",")
            }()
        )

        // Save in new format and clean up legacy keys
        state.save()
        let legacyKeys = [
            "onboardingStep", "onboardingUniversityId", "onboardingUniversityName",
            "onboardingEduEmail", "onboardingDisplayName", "onboardingHeadline",
            "onboardingMajorIds", "onboardingGradSemester", "onboardingPrograms",
            "onboardingSkillIds", "onboardingInterestIds",
            "onboardingLookingFor", "onboardingCanHelp",
        ]
        for key in legacyKeys { ud.removeObject(forKey: key) }

        return state
    }
}

// MARK: - ViewModel

@MainActor
class OnboardingViewModel: ObservableObject {

    // MARK: - Step Navigation

    @Published var step = 0
    let totalSteps = 10
    @Published var navigatingForward = true

    static func stepName(for step: Int) -> String {
        switch step {
        case 0: return "select_campus"
        case 1: return "profile_setup"
        case 2: return "select_majors"
        case 3: return "grad_year"
        case 4: return "select_programs"
        case 5: return "select_skills"
        case 6: return "select_interests"
        case 7: return "looking_for"
        case 8: return "suggested_connections"
        case 9: return "welcome"
        default: return "unknown"
        }
    }

    // MARK: - Shared State

    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Step 0: Select Campus

    @Published var campusSearch = ""
    @Published var campusResults: [UniversityResult] = []
    @Published var selectedUniversity: UniversityResult?
    @Published var defaultCampuses: [UniversityResult] = []

    // MARK: - Step 1: Profile Setup

    @Published var displayName: String = ""
    @Published var headline: String = ""
    @Published var profileImage: UIImage? {
        didSet { saveProfileImageToDisk() }
    }

    private static var profileImageURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("onboarding_profile.jpg")
    }

    // MARK: - Step 2: Majors

    @Published var majorSearch = ""
    @Published var majorResults: [MajorOption] = []
    @Published var selectedMajorIds: Set<String> = []
    @Published var allMajors: [MajorOption] = []

    // MARK: - Step 3: Grad Year

    @Published var gradSemester: String = ""

    var semesterOptions: [String] {
        let currentYear = Calendar.current.component(.year, from: Date())
        var options: [String] = []
        for year in 1980...(currentYear + 8) {
            options.append("Spring \(year)")
            options.append("Fall \(year)")
        }
        return options
    }

    // MARK: - Step 4: Programs

    @Published var availablePrograms: [String] = []
    @Published var selectedPrograms: Set<String> = []

    // MARK: - Step 5: Skills

    @Published var skillSearch = ""
    @Published var allSkills: [SkillResult] = []
    @Published var skillResults: [SkillResult] = []
    @Published var selectedSkillIds: Set<String> = []

    // MARK: - Step 6: Interests

    @Published var interestSearch = ""
    @Published var allInterests: [InterestResult] = []
    @Published var interestResults: [InterestResult] = []
    @Published var selectedInterestIds: Set<String> = []

    // MARK: - Step 7: Need Help Finding

    @Published var selectedLookingFor: Set<String> = []

    static let lookingForOptions = [
        "Co-founders",
        "Study partners",
        "Mentors",
        "Project collaborators",
        "Internship / job leads",
        "Research partners",
        "Friends to hang with",
        "Career advice",
        "Creative collaborators",
    ]

    func toggleLookingFor(_ option: String) {
        toggleSelection(option, in: &selectedLookingFor)
        persistState()
    }

    // MARK: - Step 8: Suggested Connections

    @Published var suggestedConnections: [SuggestedConnection] = []

    // MARK: - Init

    init() {
        let saved = PersistedState.load()

        step = saved.step
        displayName = saved.displayName
        headline = saved.headline
        gradSemester = saved.gradSemester
        selectedLookingFor = Set(saved.lookingFor)
        selectedMajorIds = Set(saved.majorIds)
        selectedPrograms = Set(saved.programs)
        selectedSkillIds = Set(saved.skillIds)
        selectedInterestIds = Set(saved.interestIds)

        // Restore university selection
        if !saved.universityId.isEmpty {
            selectedUniversity = UniversityResult(
                _id: saved.universityId,
                name: saved.universityName,
                shortName: nil,
                city: "",
                state: "",
                logoUrl: nil
            )
        }

        // Restore profile image from disk
        profileImage = Self.loadProfileImageFromDisk()

        // Pre-fill name from Clerk if empty
        if displayName.isEmpty, let user = Clerk.shared.user {
            let first = user.firstName ?? ""
            let last = user.lastName ?? ""
            let full = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
            if !full.isEmpty { displayName = full }
        }

        // Default grad semester to current semester
        if gradSemester.isEmpty {
            let year = Calendar.current.component(.year, from: Date())
            let month = Calendar.current.component(.month, from: Date())
            gradSemester = month <= 5 ? "Spring \(year)" : "Fall \(year)"
        }
    }

    // MARK: - Navigation

    func advance() {
        errorMessage = nil
        let stepName = Self.stepName(for: step)
        var extras: [String: Any] = [:]

        // Step-specific properties
        switch step {
        case 0:
            extras["university_name"] = selectedUniversity?.name ?? ""
        case 1:
            extras["has_photo"] = profileImage != nil
            extras["headline_length"] = headline.trimmingCharacters(in: .whitespaces).count
        case 2:
            extras["items_selected"] = selectedMajorIds.count
        case 4:
            extras["items_selected"] = selectedPrograms.count
        case 5:
            extras["items_selected"] = selectedSkillIds.count
        case 6:
            extras["items_selected"] = selectedInterestIds.count
        case 7:
            extras["items_selected"] = selectedLookingFor.count
        case 8:
            extras["connections_sent"] = sentConnectionIds.count
        default:
            break
        }

        AnalyticsService.shared.track(
            .onboardingStepCompleted(step: step, stepName: stepName),
            extraProperties: extras
        )

        navigatingForward = true

        // Save profile before showing suggested connections so user exists in DB
        if step == 7 {
            Task {
                await saveProfile()
                guard errorMessage == nil else { return }
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.35)) { step += 1 }
                    persistState()
                }
            }
            return
        }
        withAnimation(.easeInOut(duration: 0.35)) { step += 1 }
        persistState()
    }

    func goBack() {
        errorMessage = nil
        navigatingForward = false
        withAnimation(.easeInOut(duration: 0.35)) { step -= 1 }
        persistState()
    }

    // MARK: - Campus Search

    func loadDefaultCampuses() async {
        let targetSchools = [
            "University of Nebraska-Lincoln",
            "University of Nebraska at Omaha",
            "University of Nebraska at Kearney",
            "Nebraska Wesleyan",
            "Creighton",
            "Iowa State",
            "Kansas State"
        ]
        var defaults: [UniversityResult] = []
        for school in targetSchools {
            do {
                let results = try await OnboardingService.shared.searchUniversities(query: school, limit: 1)
                defaults.append(contentsOf: results)
            } catch {
                print("Default campus load error: \(error)")
            }
        }
        defaultCampuses = defaults
        if campusResults.isEmpty {
            campusResults = defaults
        }
    }

    func searchCampus(_ query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            campusResults = defaultCampuses
            return
        }

        do {
            campusResults = try await OnboardingService.shared.searchUniversities(query: trimmed)
        } catch {
            print("Campus search error: \(error)")
        }
    }

    func selectUniversity(_ university: UniversityResult) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        selectedUniversity = university
        persistState()
    }

    // MARK: - Majors

    func loadMajors() async {
        guard let name = selectedUniversity?.name,
              let universityId = selectedUniversity?._id else { return }

        // Try Convex cache first
        do {
            let grouped = try await OnboardingService.shared.getMajorsForUniversity(universityId: universityId)
            let cached = grouped.values.flatMap { $0 }.map { r in
                MajorOption(
                    cipCode: r.cipCode ?? "",
                    name: r.name,
                    credentialLevel: Int(r.credentialLevel ?? 3),
                    credentialTitle: r.credentialTitle ?? "Bachelor's Degree",
                    category: r.category,
                    convexId: r._id
                )
            }
            if !cached.isEmpty {
                allMajors = cached.sorted { $0.name < $1.name }
                majorResults = allMajors
                return
            }
        } catch {
            print("Convex majors fetch error (falling back to Scorecard): \(error)")
        }

        // Fallback: fetch from College Scorecard and cache
        do {
            let majors = try await CollegeScorecardService.shared.fetchMajors(universityName: name)
            allMajors = majors
            majorResults = allMajors

            Task {
                do {
                    let programs: [[String: Any]] = majors.map { m in
                        [
                            "cipCode": m.cipCode,
                            "name": m.name,
                            "credentialLevel": Double(m.credentialLevel),
                            "credentialTitle": m.credentialTitle,
                        ]
                    }
                    try await OnboardingService.shared.cacheMajorsForUniversity(
                        universityId: universityId,
                        programs: programs
                    )
                } catch {
                    print("Major cache error (non-blocking): \(error)")
                }
            }
        } catch {
            print("Load majors error: \(error)")
        }
    }

    func searchMajors(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { majorResults = allMajors; return }
        let lowered = trimmed.lowercased()
        majorResults = allMajors.filter { $0.displayName.lowercased().contains(lowered) }
    }

    func toggleMajor(_ major: MajorOption) {
        toggleSelection(major.id, in: &selectedMajorIds)
        persistState()
    }

    // MARK: - Programs

    func loadPrograms() async {
        guard let universityId = selectedUniversity?._id else { return }
        do {
            availablePrograms = try await OnboardingService.shared.getProgramsForUniversity(universityId: universityId)
        } catch {
            print("Load programs error: \(error)")
        }
    }

    func toggleProgram(_ program: String) {
        toggleSelection(program, in: &selectedPrograms)
        persistState()
    }

    // MARK: - Skills

    func loadSkills() async {
        if allMajors.isEmpty && !selectedMajorIds.isEmpty { await loadMajors() }
        do {
            let response = try await OnboardingService.shared.getSkills(majorCategory: selectedMajorCategory)
            let all = response.suggested + response.byCategory.values.flatMap { $0 }
            var seen = Set<String>()
            allSkills = all.filter { seen.insert($0.id).inserted }
            skillResults = allSkills
        } catch {
            print("Load skills error: \(error)")
        }
    }

    func searchSkills(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { skillResults = allSkills; return }
        let lowered = trimmed.lowercased()
        skillResults = allSkills.filter { $0.name.lowercased().contains(lowered) }
    }

    func toggleSkill(_ skill: SkillResult) {
        toggleSelection(skill.id, in: &selectedSkillIds)
        persistState()
    }

    // MARK: - Interests

    func loadInterests() async {
        if allMajors.isEmpty && !selectedMajorIds.isEmpty { await loadMajors() }
        do {
            let response = try await OnboardingService.shared.getInterests(majorCategory: selectedMajorCategory)
            let all = response.suggested + response.byCategory.values.flatMap { $0 }
            var seen = Set<String>()
            allInterests = all.filter { seen.insert($0.id).inserted }
            interestResults = allInterests
        } catch {
            print("Load interests error: \(error)")
        }
    }

    func searchInterests(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { interestResults = allInterests; return }
        let lowered = trimmed.lowercased()
        interestResults = allInterests.filter { $0.name.lowercased().contains(lowered) }
    }

    func toggleInterest(_ interest: InterestResult) {
        toggleSelection(interest.id, in: &selectedInterestIds)
        persistState()
    }

    // MARK: - Suggested Connections

    func loadSuggestedConnections() async {
        guard let universityId = selectedUniversity?._id,
              let user = Clerk.shared.user else { return }
        do {
            suggestedConnections = try await OnboardingService.shared.getSuggestedConnections(
                universityId: universityId,
                excludeClerkId: user.id,
                skills: Array(selectedSkillIds),
                interests: Array(selectedInterestIds),
                programs: Array(selectedPrograms),
                graduationSemester: gradSemester.isEmpty ? nil : gradSemester
            )
        } catch {
            print("Load suggested connections error: \(error)")
        }
    }

    // MARK: - Connection Requests

    private var savedConvexUserId: String?
    @Published var sentConnectionIds: Set<String> = []

    func sendConnectionRequest(to targetUserId: String) async {
        // Optimistic update — show "Sent!" immediately
        sentConnectionIds.insert(targetUserId)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        AnalyticsService.shared.track(.onboardingConnectionSent(targetUserId: targetUserId))

        // Try cached ID first, fall back to fetching from Convex
        var myId = savedConvexUserId
        if myId == nil, let clerkUser = Clerk.shared.user {
            print("Send connection: no cached ID, fetching from Convex...")
            let fetched = try? await ConvexClientManager.shared.fetchUserByClerkId(clerkId: clerkUser.id)
            myId = fetched?._id
            if let id = myId { savedConvexUserId = id }
        }

        guard let myId else {
            print("Send connection: could not resolve Convex user ID")
            sentConnectionIds.remove(targetUserId)
            return
        }

        do {
            let _: String? = try await ConvexClientManager.shared.client.mutation(
                "connections:sendRequest",
                with: ["requesterId": myId, "accepterId": targetUserId]
            )
            print("Send connection: sent to \(targetUserId)")
        } catch {
            print("Send connection error: \(error)")
            sentConnectionIds.remove(targetUserId)
        }
    }

    func completeOnboarding() async {
        AnalyticsService.shared.track(.onboardingCompleted)
        AnalyticsService.shared.setUserProperties([
            "university": selectedUniversity?.name ?? "",
            "grad_semester": gradSemester,
            "major_count": selectedMajorIds.count,
            "skill_count": selectedSkillIds.count,
            "interest_count": selectedInterestIds.count,
            "program_count": selectedPrograms.count,
            "has_photo": profileImage != nil,
        ])
        Self.clearAllStorage()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        await MainActor.run {
            NotificationCenter.default.post(name: .onboardingComplete, object: nil)
        }
    }

    // MARK: - Save Profile

    func saveProfile() async {
        guard let user = Clerk.shared.user else {
            errorMessage = "Not signed in"
            return
        }

        let email = user.primaryEmailAddress?.emailAddress
        let phone = user.primaryPhoneNumber?.phoneNumber
        guard email != nil || phone != nil else {
            errorMessage = "No contact info found"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // Upload avatar if user picked one
            var avatarUrl: String?
            if let image = profileImage {
                let storageId = try await ConvexClientManager.shared.uploadImage(image)
                avatarUrl = storageId
            }

            // Build major inputs from selected IDs
            let majorInputs: [MajorInput]? = selectedMajorIds.isEmpty ? nil : allMajors
                .filter { selectedMajorIds.contains($0.id) }
                .compactMap { major in
                    guard let convexId = major.convexId else { return nil }
                    return MajorInput(majorId: convexId, credentialLevel: major.credentialLevel)
                }

            let input = UserInput(
                clerkId: user.id,
                email: email,
                phone: phone,
                name: displayName,
                headline: headline.isEmpty ? nil : headline,
                avatarUrl: avatarUrl,
                universityId: selectedUniversity?._id,
                majors: majorInputs,
                graduationSemester: gradSemester.isEmpty ? nil : gradSemester,
                programs: selectedPrograms.isEmpty ? nil : Array(selectedPrograms),
                skills: selectedSkillIds.isEmpty ? nil : Array(selectedSkillIds),
                interests: selectedInterestIds.isEmpty ? nil : Array(selectedInterestIds),
                lookingFor: selectedLookingFor.isEmpty ? nil : Array(selectedLookingFor).joined(separator: ", "),
                canHelpWith: nil
            )

            let result = try await ConvexClientManager.shared.upsertUser(input)
            savedConvexUserId = result
            print("Onboarding: Profile saved successfully - \(result)")
        } catch {
            print("Onboarding: Error saving profile - \(error)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Helpers

    /// Shared toggle logic for set-based selections with haptic feedback
    private func toggleSelection<T: Hashable>(_ item: T, in set: inout Set<T>) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if set.contains(item) { set.remove(item) } else { set.insert(item) }
    }

    /// Major category derived from first selected major (used by skills/interests loading)
    private var selectedMajorCategory: String? {
        guard !selectedMajorIds.isEmpty else { return nil }
        let cat = allMajors.first(where: { selectedMajorIds.contains($0.id) })?.category
        return (cat?.isEmpty ?? true) ? nil : cat
    }

    /// Avatar data for welcome screen bubbles — connections first, then user, then generic fillers
    func avatarForBubbleIndex(_ index: Int) -> (url: String?, initials: String) {
        if index < suggestedConnections.count {
            let c = suggestedConnections[index]
            return (c.avatarUrl, Self.initials(from: c.name))
        }
        if profileImage != nil {
            return (nil, Self.initials(from: displayName))
        }
        let fillers = ["JU", "NT", "GO"]
        let fillerIndex = index - suggestedConnections.count
        return (nil, fillers[fillerIndex % fillers.count])
    }

    /// Extract initials from a name (e.g. "Kenny Morales" → "KM")
    static func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    // MARK: - Persistence

    /// Serializes current state to a single UserDefaults key
    private func persistState() {
        PersistedState(
            step: step,
            universityId: selectedUniversity?._id ?? "",
            universityName: selectedUniversity?.name ?? "",
            displayName: displayName,
            headline: headline,
            majorIds: Array(selectedMajorIds),
            gradSemester: gradSemester,
            programs: Array(selectedPrograms),
            skillIds: Array(selectedSkillIds),
            interestIds: Array(selectedInterestIds),
            lookingFor: Array(selectedLookingFor)
        ).save()
    }

    // MARK: - Reset (on complete or sign out)

    func reset() {
        Self.clearAllStorage()
        step = 0
        displayName = ""
        headline = ""
        gradSemester = ""
        selectedLookingFor = []
        profileImage = nil
        selectedUniversity = nil
        selectedMajorIds = []
        selectedPrograms = []
        selectedSkillIds = []
        selectedInterestIds = []
        suggestedConnections = []
        sentConnectionIds = []
        savedConvexUserId = nil
    }

    /// Clears all persisted onboarding data — callable without a ViewModel instance
    static func clearAllStorage() {
        PersistedState.clear()
        deleteProfileImageFromDisk()
    }

    // MARK: - Profile Image Persistence

    private func saveProfileImageToDisk() {
        guard let image = profileImage,
              let data = image.jpegData(compressionQuality: 0.8) else {
            Self.deleteProfileImageFromDisk()
            return
        }
        try? data.write(to: Self.profileImageURL)
    }

    private static func loadProfileImageFromDisk() -> UIImage? {
        guard FileManager.default.fileExists(atPath: profileImageURL.path) else { return nil }
        return UIImage(contentsOfFile: profileImageURL.path)
    }

    static func deleteProfileImageFromDisk() {
        try? FileManager.default.removeItem(at: profileImageURL)
    }
}
