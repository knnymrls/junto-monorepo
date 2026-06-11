//
//  MakerSearchView.swift
//  junto
//
//  The People search page. Pushed from the People list, it zoom-grows out of
//  the Search pill so it feels like the pill expands into a full-width search
//  bar. A back arrow (and the native left-edge swipe) pop back to the list.
//  Live results reuse the same DiscoverPersonCard rows as the browse list.
//

import SwiftUI

struct MakerSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var currentUser: CurrentUserManager
    @StateObject private var viewModel = SearchViewModel()

    @State private var selectedUserProfile: UserResponse?
    @FocusState private var searchFocused: Bool

    @Namespace private var profileZoom

    private var people: [UserResponse] { viewModel.liveResults }
    private var query: String {
        viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            results
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        .fullScreenCover(item: $selectedUserProfile) { user in
            ProfileView(user: user)
                .zoomDestination(id: user._id, in: profileZoom)
        }
        .onAppear {
            // Focus once the grow transition settles so the keyboard doesn't
            // fight the animation.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                searchFocused = true
            }
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

    // MARK: - Header (back + full-width search bar)

    private var header: some View {
        HStack(spacing: Spacing.sm) {
            DiscoverCircleButton(icon: .navBack, action: { dismiss() })

            HStack(spacing: Spacing.sm) {
                Image(.navSearch)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundColor(.appSecondary)

                TextField("Search", text: $viewModel.searchText)
                    .font(.bodyLargeMedium)
                    .foregroundColor(.appPrimary)
                    .tint(.appPrimary)
                    .focused($searchFocused)
                    .submitLabel(.search)

                if !viewModel.searchText.isEmpty {
                    Button { viewModel.searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.appSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .frame(maxWidth: .infinity)
            .frame(height: 37)
            .background(Color.appSurfaceSecondary, in: Capsule())
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.sm)
        .background(Color.appSurface.ignoresSafeArea(edges: .top))
    }

    // MARK: - Results

    @ViewBuilder
    private var results: some View {
        if query.isEmpty {
            VStack {
                Spacer()
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "Search for makers",
                    subtitle: "Find people by name, skill, or what they're building"
                )
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if people.isEmpty {
            VStack {
                Spacer()
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "No users found",
                    subtitle: "Try different keywords or a broader search"
                )
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(people) { user in
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
}
