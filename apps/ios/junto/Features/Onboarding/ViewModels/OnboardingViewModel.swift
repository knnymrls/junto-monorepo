//
//  OnboardingViewModel.swift
//  junto
//
//  Manages onboarding flow state, persistence, and Clerk .edu verification
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
    var eduEmail: String = ""
    var displayName: String = ""
    var headline: String = ""
    var majorIds: [String] = []
    var gradSemester: String = ""
    var programs: [String] = []
    var skillIds: [String] = []
    var interestIds: [String] = []
    var lookingFor: [String] = []

    private static let key = "onboardingState"

    static func load() -> PersistedState {
        // Try new single-key format first
        if let data = UserDefaults.standard.data(forKey: key),
           let state = try? JSONDecoder().decode(PersistedState.self, from: data) {
            return state
        }
        // Migrate from legacy @AppStorage keys (one-time)
        return migrateLegacyKeys()
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.key)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
        // Also clear legacy keys in case they exist
        let legacyKeys = [
            "onboardingStep", "onboardingUniversityId", "onboardingUniversityName",
            "onboardingEduEmail", "onboardingDisplayName", "onboardingHeadline",
            "onboardingMajorIds", "onboardingGradSemester", "onboardingPrograms",
            "onboardingSkillIds", "onboardingInterestIds",
            "onboardingLookingFor", "onboardingCanHelp",  // canHelp kept for cleanup
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

        let state = PersistedState(
            step: step,
            universityId: ud.string(forKey: "onboardingUniversityId") ?? "",
            universityName: ud.string(forKey: "onboardingUniversityName") ?? "",
            eduEmail: ud.string(forKey: "onboardingEduEmail") ?? "",
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
            "onboardingLookingFor", "onboardingCanHelp",  // canHelp kept for cleanup
        ]
        for key in legacyKeys { ud.removeObject(forKey: key) }

        return state
    }
}

// MARK: - ViewModel

@MainActor
class OnboardingViewModel: ObservableObject {

    // MARK: - Invite Link

    @Published var inviteCode: String?
    @Published var inviteLink: InviteLinkResponse?
    @Published var isLoadingInvite = false

    /// Called when the app is opened via an invite link.
    /// Resolves the code, pre-fills university + program, and jumps past campus/program selection.
    func applyInviteCode(_ code: String) async {
        inviteCode = code
        isLoadingInvite = true

        do {
            let link = try await ConvexClientManager.shared.getInviteLinkByCode(code: code)
            guard let link else {
                errorMessage = "This invite link is no longer valid."
                isLoadingInvite = false
                return
            }

            inviteLink = link

            // Pre-fill university from invite
            selectedUniversity = UniversityResult(
                _id: link.universityId,
                name: link.universityName,
                shortName: link.universityShortName,
                city: link.universityCity,
                state: link.universityState,
                logoUrl: link.universityLogoUrl
            )

            // Pre-fill program if specified
            if let program = link.program {
                selectedPrograms = [program]
            }

            // Pre-fill role if specified
            if let role = link.role {
                inviteRole = role
            }

            persistState()
        } catch {
            print("Invite link resolution error: \(error)")
            errorMessage = "Couldn't load invite details. Try again."
        }

        isLoadingInvite = false
    }

    /// Redeem the invite link after onboarding completes
    func redeemInviteIfNeeded(userId: String) async {
        guard let code = inviteCode else { return }
        do {
            let _ = try await ConvexClientManager.shared.redeemInviteLink(code: code, userId: userId)
        } catch {
            print("Invite redeem error (non-blocking): \(error)")
        }
    }

    @Published var inviteRole: String?

    // MARK: - Step Navigation

    @Published var step = 0
    let totalSteps = 10
    @Published var navigatingForward = true

    static func stepName(for step: Int) -> String {
        switch step {
        case 0: return "select_campus"
        case 1: return "school_email"
        case 2: return "verify_email"
        case 3: return "profile_setup"
        case 4: return "select_majors"
        case 5: return "grad_year"
        case 6: return "select_programs"
        case 7: return "select_skills"
        case 8: return "select_interests"
        case 9: return "looking_for"
        case 10: return "suggested_connections"
        case 11: return "welcome"
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

    // MARK: - Steps 1-2: School Email

    @Published var eduEmail: String = ""
    @Published var eduCode = ""
    @Published var isVerifyingEdu = false
    @Published var eduResendCooldown = 0
    @Published var eduVerified = false
    private var cooldownTimer: Timer?

    var isValidEduEmail: Bool {
        eduEmail.lowercased().hasSuffix(".edu") && eduEmail.contains("@")
    }

    // MARK: - Step 3: Profile Setup

    @Published var displayName: String = ""
    @Published var headline: String = ""
    @Published var profileImage: UIImage? {
        didSet { saveProfileImageToDisk() }
    }

    private static var profileImageURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("onboarding_profile.jpg")
    }

    // MARK: - Step 4: Majors

    @Published var majorSearch = ""
    @Published var majorResults: [MajorOption] = []
    @Published var selectedMajorIds: Set<String> = []
    @Published var allMajors: [MajorOption] = []

    // MARK: - Step 5: Grad Year

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

    // MARK: - Step 6: Programs

    @Published var availablePrograms: [String] = []
    @Published var selectedPrograms: Set<String> = []

    // MARK: - Step 7: Skills

    @Published var skillSearch = ""
    @Published var allSkills: [SkillResult] = []
    @Published var skillResults: [SkillResult] = []
    @Published var selectedSkillIds: Set<String> = []

    // MARK: - Step 8: Interests

    @Published var interestSearch = ""
    @Published var allInterests: [InterestResult] = []
    @Published var interestResults: [InterestResult] = []
    @Published var selectedInterestIds: Set<String> = []

    // MARK: - Step 9: Need Help Finding

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

    // MARK: - Step 11: Suggested Connections

    @Published var suggestedConnections: [SuggestedConnection] = []

    // MARK: - Init

    init() {
        let saved = PersistedState.load()

        step = saved.step
        eduEmail = saved.eduEmail
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

        // Check for pending invite code from URL (persisted across auth flow)
        if let pendingCode = UserDefaults.standard.string(forKey: "pendingInviteCode") {
            Task { await applyInviteCode(pendingCode) }
        }
    }

    // MARK: - Navigation

    /// The step number for the invite confirmation screen (inserted when invite is active)
    var inviteConfirmationStep: Int? { inviteLink != nil ? 0 : nil }

    /// Whether current step is the invite confirmation screen
    var isInviteConfirmationStep: Bool { inviteLink != nil && step == 0 }

    func advance() {
        errorMessage = nil
        let stepName = Self.stepName(for: step)
        var extras: [String: Any] = [:]

        // Step-specific properties
        switch step {
        case 0:
            extras["university_name"] = selectedUniversity?.name ?? ""
            if inviteLink != nil {
                extras["invite_code"] = inviteCode ?? ""
            }
        case 3:
            extras["has_photo"] = profileImage != nil
            extras["headline_length"] = headline.trimmingCharacters(in: .whitespaces).count
        case 4:
            extras["items_selected"] = selectedMajorIds.count
        case 6:
            extras["items_selected"] = selectedPrograms.count
        case 7:
            extras["items_selected"] = selectedSkillIds.count
        case 8:
            extras["items_selected"] = selectedInterestIds.count
        case 9:
            extras["items_selected"] = selectedLookingFor.count
        case 10:
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
        if step == 9 {
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

        var nextStep = step + 1

        // Skip steps that invite link already handles
        if inviteLink != nil {
            // After invite confirmation (step 0), skip school email (1) and verify (2)
            // → go straight to profile setup (step 3)
            if nextStep == 1 {
                nextStep = 3
            }

            // Skip program selection (step 6) if invite pre-filled a program
            if nextStep == 6 && inviteLink?.program != nil {
                nextStep = 7
            }
        }

        withAnimation(.easeInOut(duration: 0.35)) { step = nextStep }
        persistState()
    }

    func goBack() {
        errorMessage = nil
        navigatingForward = false

        var prevStep = step - 1

        // Skip steps that invite link already handles (reverse direction)
        if inviteLink != nil {
            // From profile setup (3), go back to invite confirmation (0)
            if prevStep == 2 || prevStep == 1 {
                prevStep = 0
            }
            // From skills (7), skip program selection (6) if invite pre-filled
            if prevStep == 6 && inviteLink?.program != nil {
                prevStep = 5
            }
        }

        withAnimation(.easeInOut(duration: 0.35)) { step = prevStep }
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

    // MARK: - Edu Email Verification (Clerk)

    func sendEduCode() async {
        guard let user = Clerk.shared.user else {
            errorMessage = "Not signed in"
            return
        }

        // If already verified (e.g. went back), skip straight to step 3
        if let existing = user.emailAddresses.first(where: { $0.emailAddress == eduEmail }) {
            if existing.verification?.status == .verified {
                eduVerified = true
                AnalyticsService.shared.track(.onboardingStepCompleted(step: step, stepName: Self.stepName(for: step)))
                navigatingForward = true
                withAnimation(.easeInOut(duration: 0.35)) { step = 3 }
                persistState()
                return
            }
            // Exists but not verified locally — try to resend code
            isVerifyingEdu = true
            errorMessage = nil
            do {
                try await existing.prepareVerification(strategy: .emailCode)
                startCooldown()
                advance()
            } catch {
                // If already verified on Clerk's side, just advance
                if "\(error)".contains("already been verified") {
                    eduVerified = true
                    navigatingForward = true
                    withAnimation(.easeInOut(duration: 0.35)) { step = 3 }
                    persistState()
                } else {
                    errorMessage = error.localizedDescription
                }
            }
            isVerifyingEdu = false
            return
        }

        // New email — create and send code
        isVerifyingEdu = true
        errorMessage = nil

        do {
            let emailAddress = try await user.createEmailAddress(eduEmail)
            try await emailAddress.prepareVerification(strategy: .emailCode)
            startCooldown()
            advance()
        } catch {
            errorMessage = error.localizedDescription
        }

        isVerifyingEdu = false
    }

    func verifyEduCode() async {
        guard let user = Clerk.shared.user,
              let emailAddress = user.emailAddresses.first(where: { $0.emailAddress == eduEmail })
        else {
            errorMessage = "No pending verification"
            return
        }

        isVerifyingEdu = true
        errorMessage = nil

        do {
            try await emailAddress.attemptVerification(strategy: .emailCode(code: eduCode))
            eduVerified = true
            isVerifyingEdu = false
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            // Brief pause to show success before advancing
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            advance()
            return
        } catch {
            errorMessage = error.localizedDescription
        }

        isVerifyingEdu = false
    }

    func resendEduCode() async {
        guard eduResendCooldown == 0,
              let user = Clerk.shared.user,
              let emailAddress = user.emailAddresses.first(where: { $0.emailAddress == eduEmail })
        else { return }

        isVerifyingEdu = true
        errorMessage = nil
        eduCode = ""

        do {
            try await emailAddress.prepareVerification(strategy: .emailCode)
            startCooldown()
        } catch {
            errorMessage = error.localizedDescription
        }

        isVerifyingEdu = false
    }

    func checkEduAlreadyVerified() async {
        guard !eduEmail.isEmpty,
              let user = Clerk.shared.user,
              let existing = user.emailAddresses.first(where: { $0.emailAddress == eduEmail }),
              existing.verification?.status == .verified
        else { return }

        eduVerified = true
        withAnimation { step = 3 }
        persistState()
    }

    private func startCooldown() {
        eduResendCooldown = 30
        cooldownTimer?.invalidate()
        cooldownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self else { timer.invalidate(); return }
                self.eduResendCooldown -= 1
                if self.eduResendCooldown <= 0 {
                    self.eduResendCooldown = 0
                    timer.invalidate()
                }
            }
        }
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

    // MARK: - Step 11: Suggested Connections

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
        // Redeem invite link if user came in via one
        if let userId = savedConvexUserId {
            await redeemInviteIfNeeded(userId: userId)
        }

        var properties: [String: Any] = [
            "university": selectedUniversity?.name ?? "",
            "grad_semester": gradSemester,
            "major_count": selectedMajorIds.count,
            "skill_count": selectedSkillIds.count,
            "interest_count": selectedInterestIds.count,
            "program_count": selectedPrograms.count,
            "has_photo": profileImage != nil,
        ]
        if let code = inviteCode {
            properties["invite_code"] = code
        }

        AnalyticsService.shared.track(.onboardingCompleted)
        AnalyticsService.shared.setUserProperties(properties)
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
                canHelpWith: nil,
                role: inviteRole
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
            eduEmail: eduEmail,
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
        eduEmail = ""
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
        inviteCode = nil
        inviteLink = nil
        inviteRole = nil
    }

    /// Clears all persisted onboarding data — callable without a ViewModel instance
    static func clearAllStorage() {
        PersistedState.clear()
        deleteProfileImageFromDisk()
        UserDefaults.standard.removeObject(forKey: "pendingInviteCode")
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
