//
//  SearchViewPreviews.swift
//  mkrs-world
//
//  Preview variants for the search sheet
//

import SwiftUI

// MARK: - Preview Helpers

extension SearchViewModel {
    static func preview(phase: SearchPhase, results: [SearchResultItem] = []) -> SearchViewModel {
        let vm = SearchViewModel()
        vm.searchPhase = phase
        return vm
    }
}

private let mockUsers: [UserResponse] = (0..<8).map { i in
    UserResponse(
        _id: "user_\(i)",
        clerkId: "clerk_\(i)",
        email: "user\(i)@test.com",
        phone: nil,
        name: ["Alex Chen", "Jordan Rivera", "Sam Kim", "Morgan Lee", "Taylor Swift", "Casey Park", "Riley Johnson", "Drew Martinez"][i],
        headline: ["iOS Developer", "UX Designer", "Full-Stack Builder", "Marketing Lead", "Product Manager", nil, "AI Researcher", "Startup Founder"][i],
        avatarUrl: nil,
        universityId: nil,
        majors: nil,
        graduationSemester: nil,
        programs: nil,
        skills: [["Swift", "iOS", "SwiftUI"], ["Figma", "UX"], ["React", "Node"], ["Growth", "SEO"], ["Strategy"], nil, ["ML", "Python"], ["Sales"]][i],
        interests: [["AI", "Mobile"], ["Design"], ["Web3"], ["Content"], ["SaaS"], nil, ["NLP"], ["B2B"]][i],
        lookingFor: nil,
        canHelpWith: nil,
        currentProject: nil,
        socialLinks: nil,
        role: "student",
        platformRole: nil,
        status: nil,
        isOnboarded: true,
        createdAt: Date().timeIntervalSince1970 * 1000,
        updatedAt: Date().timeIntervalSince1970 * 1000
    )
}

private let mockResults: [SearchResultItem] = mockUsers.prefix(6).map { user in
    SearchResultItem(
        userId: user._id,
        explanation: [
            "Expert iOS developer with deep SwiftUI knowledge, currently building a health app",
            "Talented UX designer specializing in mobile apps",
            "Full-stack developer who can help with both frontend and backend",
            "Growth marketing specialist with startup experience",
            "Experienced PM who's shipped multiple products",
            "AI researcher exploring practical applications"
        ].randomElement()!,
        relevanceScore: Double.random(in: 0.5...0.95),
        mutualConnectionCount: Int.random(in: 0...3),
        mutualConnectionNames: ["Wilson O."],
        connectionStatus: nil,
        isAIEnhanced: nil
    )
}

private let mockEnhancedResults: [SearchResultItem] = mockResults.map { result in
    SearchResultItem(
        userId: result.userId,
        explanation: "AI-personalized: " + result.explanation,
        relevanceScore: result.relevanceScore,
        mutualConnectionCount: result.mutualConnectionCount,
        mutualConnectionNames: result.mutualConnectionNames,
        connectionStatus: result.connectionStatus,
        isAIEnhanced: true
    )
}

// MARK: - Previews

#Preview("Typing (Masonry Results)") {
    SearchSheetTypingPreview()
}

#Preview("Streaming") {
    SearchSheetStreamingPreview()
}

#Preview("Enhanced Results") {
    SearchSheetEnhancedPreview()
}

#Preview("No Results") {
    SearchSheetNoResultsPreview()
}

// MARK: - Preview Views

private struct SearchSheetTypingPreview: View {
    @StateObject private var vm: SearchViewModel = {
        let vm = SearchViewModel()
        vm.searchPhase = .typing
        vm.searchText = "Alex"
        // Name results appear first (instant), then vector results enrich
        vm.nameResults = Array(mockResults.prefix(2))
        vm.vectorResults = Array(mockResults.prefix(4))
        for user in mockUsers {
            vm.userProfiles[user._id] = user
        }
        return vm
    }()

    var body: some View {
        previewShell(vm: vm)
    }
}

private struct SearchSheetStreamingPreview: View {
    @StateObject private var vm: SearchViewModel = {
        let vm = SearchViewModel()
        vm.searchPhase = .streaming
        vm.searchText = "iOS developer for my startup"
        vm.vectorResults = mockResults
        vm.streamingThinking = "I found several users with strong iOS backgrounds. Alex Chen stands out with SwiftUI expertise..."
        vm.streamingResults = Array(mockEnhancedResults.prefix(3))
        for user in mockUsers {
            vm.userProfiles[user._id] = user
        }
        return vm
    }()

    var body: some View {
        previewShell(vm: vm)
    }
}

private struct SearchSheetEnhancedPreview: View {
    @StateObject private var vm: SearchViewModel = {
        let vm = SearchViewModel()
        vm.searchPhase = .enhanced
        vm.searchText = "iOS developer for my startup"
        vm.enhancedResults = mockEnhancedResults
        vm.aiThinking = "I found 6 users with strong iOS and mobile development backgrounds. Alex Chen stands out with SwiftUI expertise, and Jordan has relevant UX design skills for a startup context."
        for user in mockUsers {
            vm.userProfiles[user._id] = user
        }
        return vm
    }()

    var body: some View {
        previewShell(vm: vm)
    }
}

private struct SearchSheetNoResultsPreview: View {
    @StateObject private var vm: SearchViewModel = {
        let vm = SearchViewModel()
        vm.searchPhase = .enhanced
        vm.searchText = "quantum physicist"
        vm.enhancedResults = []
        return vm
    }()

    var body: some View {
        previewShell(vm: vm)
    }
}

// MARK: - Preview Shell

@MainActor
private func previewShell(vm: SearchViewModel) -> some View {
    ZStack(alignment: .bottom) {
        Color.appBackground
            .ignoresSafeArea()

        // Results
        ScrollView {
            VStack(spacing: Spacing.sm) {
                if !vm.displayResults.isEmpty {
                    MasonryLayout(spacing: Spacing.sm) {
                        ForEach(Array(vm.displayResults.enumerated()), id: \.element.id) { index, result in
                            if let user = vm.userProfiles[result.userId] {
                                SearchMasonryCard(
                                    result: result,
                                    user: user,
                                    connectionStatus: .none,
                                    onTap: {},
                                    onConnect: {},
                                    appearDelay: Double(index) * 0.08
                                )
                            }
                        }
                    }
                } else if vm.searchPhase == .enhanced {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No users found",
                        subtitle: "Try different keywords"
                    )
                    .padding(.top, Spacing.xxl)
                }

                Spacer().frame(height: 140)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.top, Spacing.sm)
        }

        // Floating AI insights
        if vm.searchPhase == .streaming || (vm.aiThinking != nil && vm.searchPhase == .enhanced) {
            HStack(alignment: .top, spacing: Spacing.xs) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.appPrimary)

                Text(vm.searchPhase == .streaming ? vm.streamingThinking : (vm.aiThinking ?? ""))
                    .font(.caption12)
                    .foregroundColor(.appSecondary)
                    .lineLimit(3)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
            .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, 80)
        }

        // Bottom input
        HStack(alignment: .bottom, spacing: Spacing.sm) {
            Text(vm.searchText.isEmpty ? "Search users..." : vm.searchText)
                .font(.body14)
                .foregroundColor(vm.searchText.isEmpty ? .appSecondary : .appPrimary)
                .frame(height: 28, alignment: .center)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Spacing.md)
        
        .padding(.vertical, 10)
        .background(Color.appSurfaceSecondary)
        .cornerRadius(27)
        .padding(.horizontal, 10)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.md)
    }
}
