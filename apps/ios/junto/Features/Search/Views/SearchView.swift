//
//  SearchView.swift
//  mkrs-world
//
//  Search tab — auto-opens the search sheet on appear
//

import SwiftUI
import Clerk

struct SearchView: View {
    @EnvironmentObject private var currentUser: CurrentUserManager

    var body: some View {
        SearchSheet()
            .environmentObject(currentUser)
            .onAppear {
                AnalyticsService.shared.track(.searchViewed)
            }
    }
}

// MARK: - Search Sheet

struct SearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var currentUser: CurrentUserManager
    @StateObject private var viewModel = SearchViewModel()
    @State private var selectedUserProfile: UserResponse?
    @State private var searchTextHeight: CGFloat = 28
    @State private var isInputFocused = false
    // Dummy bindings for ReplyComposerBar (not using media in search)
    @State private var dummyImage: UIImage? = nil
    @State private var dummyGifUrl: URL? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            // Scrollable content (full height)
            contentArea

            // Floating AI insights card (above input)
            if showInsightsCard {
                aiInsightsCard
                    .padding(.bottom, 80) // Above the input bar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Bottom input bar — same ReplyComposerBar pattern, no background
            searchComposerBar
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.searchPhase)
        .animation(.easeInOut(duration: 0.3), value: viewModel.aiThinking != nil)
        .animation(.easeInOut(duration: 0.3), value: showInsightsCard)
        .background(Color.appBackground)
        .sheet(item: $selectedUserProfile) { user in
            ProfileView(user: user)
        }
        .task {
            if let userId = currentUser.userId {
                viewModel.currentUserId = userId
                viewModel.startListening()
                await viewModel.loadConnections(userId: userId)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isInputFocused = true
            }
        }
    }

    // MARK: - Content Area

    @ViewBuilder
    private var contentArea: some View {
        switch viewModel.searchPhase {
        case .idle:
            idleHint

        case .typing, .submitted, .streaming, .enhanced:
            resultsView
        }
    }

    // MARK: - Idle Hint

    private var idleHint: some View {
        VStack(spacing: Spacing.sm) {
            Spacer()

            Image(systemName: "sparkle.magnifyingglass")
                .font(.system(size: 28))
                .foregroundColor(.appSecondary)

            Text("Search by name, skills,\ngoals, or interests")
                .font(.body14)
                .foregroundColor(.appSecondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Results View

    private var resultsView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Spacing.sm) {
                // Masonry grid
                if !viewModel.displayResults.isEmpty {
                    masonryGrid
                } else if viewModel.searchPhase == .submitted || viewModel.searchPhase == .streaming {
                    masonrySkeleton
                } else if viewModel.searchPhase != .typing {
                    VStack(spacing: Spacing.md) {
                        Spacer()
                        EmptyStateView(
                            icon: "magnifyingglass",
                            title: "No users found",
                            subtitle: "Try different keywords or a broader search"
                        )
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, Spacing.xxl)
                }

                // Bottom spacer so content isn't hidden behind input + insights
                Spacer().frame(height: 200)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.top, Spacing.md)
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.searchPhase)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.displayResults.map(\.userId))
    }

    // MARK: - Floating AI Insights Card

    private var aiInsightsCard: some View {
        HStack(alignment: .top, spacing: Spacing.xs) {
            if viewModel.searchPhase == .submitted {
                // Searching phase — pulsing icon + "Finding users..."
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.appPrimary)
                    .symbolEffect(.pulse, options: .repeating)

                HStack(spacing: Spacing.xs) {
                    Text("Finding users")
                        .font(.caption12)
                        .foregroundColor(.appSecondary)
                    TypingDots()
                }
            } else if viewModel.searchPhase == .streaming {
                // Streaming phase — thinking text grows in real-time
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.appPrimary)
                    .symbolEffect(.pulse, options: .repeating)

                if viewModel.streamingThinking.isEmpty {
                    HStack(spacing: Spacing.xs) {
                        Text("Analyzing matches")
                            .font(.caption12)
                            .foregroundColor(.appSecondary)
                        TypingDots()
                    }
                } else {
                    Text(viewModel.streamingThinking)
                        .font(.caption12)
                        .foregroundColor(.appSecondary)
                        .lineLimit(3)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.streamingThinking)
                }
            } else if let thinking = viewModel.aiThinking {
                // Enhanced phase — final AI summary
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.appPrimary)

                Text(thinking)
                    .font(.caption12)
                    .foregroundColor(.appSecondary)
                    .lineLimit(3)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        .padding(.horizontal, Spacing.md)
    }

    // MARK: - Search Composer Bar (ReplyComposerBar pattern)

    private var searchComposerBar: some View {
        HStack(alignment: .bottom, spacing: Spacing.sm) {
            if !isInputActive {
                AvatarView(
                    avatarUrl: currentUser.user?.avatarUrl,
                    name: currentUser.user?.name ?? "?",
                    size: 28
                )
                .transition(
                    .asymmetric(
                        insertion: .scale(scale: 0.5).combined(with: .opacity),
                        removal: .scale(scale: 0.5).combined(with: .opacity)
                    )
                )
            }

            ZStack(alignment: .leading) {
                if viewModel.searchText.isEmpty {
                    Text("Search users...")
                        .font(.body14)
                        .foregroundColor(.appSecondary)
                        .allowsHitTesting(false)
                        .frame(height: 28, alignment: .center)
                }

                MentionTextView(
                    text: $viewModel.searchText,
                    height: $searchTextHeight,
                    placeholder: "Search users...",
                    minHeight: 28,
                    autoFocus: true,
                    returnKeyType: .search,
                    onTextChange: { _ in },
                    onSubmit: {
                        viewModel.submitSearch()
                    }
                )
                .frame(height: searchTextHeight)
            }
            .frame(minHeight: 28)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 10)
        .background(Color.appSurfaceSecondary)
        .cornerRadius(27)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isInputActive)
        .padding(.horizontal, 10)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.md)
    }

    private var isInputActive: Bool {
        isInputFocused || !viewModel.searchText.isEmpty
    }

    private var showInsightsCard: Bool {
        switch viewModel.searchPhase {
        case .submitted:
            return true
        case .streaming:
            return true
        case .enhanced:
            return viewModel.aiThinking != nil
        default:
            return false
        }
    }

    // MARK: - Masonry Grid

    private var masonryGrid: some View {
        MasonryLayout(spacing: Spacing.sm) {
            ForEach(Array(viewModel.displayResults.enumerated()), id: \.element.id) { index, result in
                if let user = viewModel.userProfiles[result.userId] {
                    SearchMasonryCard(
                        result: result,
                        user: user,
                        connectionStatus: viewModel.connectionStatus(for: result),
                        onTap: {
                            selectedUserProfile = user
                        },
                        onConnect: {
                            Task {
                                AnalyticsService.shared.track(.connectFromSearch(toUserId: result.userId))
                                _ = await viewModel.sendConnectionRequest(toUserId: result.userId)
                            }
                        },
                        appearDelay: Double(index) * 0.08,
                        isEnhancing: viewModel.enhancingUserIds.contains(result.userId)
                    )
                }
            }
        }
    }

    // MARK: - Masonry Skeleton

    private var masonrySkeleton: some View {
        let heights: [CGFloat] = [140, 170, 155, 185, 150, 165]
        return MasonryLayout(spacing: Spacing.sm) {
            ForEach(0..<6, id: \.self) { index in
                SearchMasonryCardSkeleton(height: heights[index])
            }
        }
    }
}
