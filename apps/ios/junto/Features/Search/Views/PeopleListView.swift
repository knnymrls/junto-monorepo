//
//  PeopleListView.swift
//  junto
//
//  Discover's "People you should know" drill-in: a back button + Search pill +
//  filter over a list of suggested people. Tapping the Search pill pushes the
//  search page, which zoom-grows out of the pill (back arrow + native
//  swipe-back). Matches the Discover people artboard (Paper 7ZX-0).
//

import SwiftUI

struct PeopleListView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var currentUser: CurrentUserManager
    @StateObject private var viewModel = SearchViewModel()

    /// Pushes the search page (owned by DiscoverView's stack).
    var onSearchTap: () -> Void = {}
    /// When set, the list is scoped to one skill category (Browse By Category).
    var category: SkillCategory? = nil

    @State private var selectedUserProfile: UserResponse?

    @Namespace private var profileZoom

    private var people: [UserResponse] { viewModel.liveResults }

    /// People shown — all suggestions, or just those whose skills/interests
    /// map to the selected category.
    private var displayedPeople: [UserResponse] {
        guard let category else { return people }
        return people.filter { user in
            (user.skillCategories ?? []).contains(category.label)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            DiscoverListTopBar(onBack: { dismiss() }, onFilter: {}) {
                if let category {
                    Text(category.label)
                        .font(.bodyLargeSemibold)
                        .foregroundColor(.appPrimary)
                } else {
                    DiscoverSearchPill { onSearchTap() }
                }
            }

            if !viewModel.hasLoadedDefaults {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(0..<7, id: \.self) { _ in DiscoverPersonCardSkeleton() }
                    }
                    .padding(.top, Spacing.sm)
                }
                .scrollEdgeFade(top: true, bottom: false)
            } else if displayedPeople.isEmpty {
                Spacer()
                Text(category == nil ? "No makers yet" : "No \(category!.label) makers yet")
                    .font(.body14)
                    .foregroundColor(.appSecondary)
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(displayedPeople) { user in
                            DiscoverPersonCard(
                                user: user,
                                connectionStatus: viewModel.connectionStatus(forUserId: user._id),
                                isSelf: user._id == currentUser.userId,
                                onTap: { selectedUserProfile = user },
                                onConnect: {
                                    Task {
                                        AnalyticsService.shared.track(.connectFromSearch(toUserId: user._id))
                                        _ = await viewModel.sendConnectionRequest(toUserId: user._id)
                                    }
                                },
                                profileZoomID: AnyHashable(user._id),
                                profileZoomNamespace: profileZoom
                            )
                            .zoomSource(id: user._id, in: profileZoom)
                        }
                        Color.clear.frame(height: 32)
                    }
                    .padding(.top, Spacing.sm)
                }
                .scrollEdgeFade(top: true, bottom: false)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        .fullScreenCover(item: $selectedUserProfile) { user in
            ProfileView(user: user)
                .zoomDestination(id: user._id, in: profileZoom)
        }
        .task {
            if let userId = currentUser.userId {
                viewModel.currentUserId = userId
                viewModel.startListening()
                viewModel.loadDefaultUsers()
                await viewModel.loadConnections(userId: userId)
            }
        }
    }
}
