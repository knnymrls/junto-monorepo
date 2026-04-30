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
    @Environment(\.tabBarVisible) private var tabBarVisible
    @EnvironmentObject private var currentUser: CurrentUserManager
    @StateObject private var viewModel = SearchViewModel()
    @State private var selectedUserProfile: UserResponse?
    @State private var keyboardHeight: CGFloat = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            contentArea

            VStack(spacing: Spacing.sm) {
                if showInsightsCard {
                    aiInsightsCard
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else if showAISuggestion {
                    aiSearchSuggestion
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                searchComposerBar
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, keyboardHeight > 0 ? keyboardHeight - bottomSafeArea + Spacing.sm : 72)
            .animation(.easeInOut(duration: 0.2), value: showAISuggestion)
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.searchPhase)
        .animation(.easeInOut(duration: 0.3), value: viewModel.aiThinking != nil)
        .animation(.easeInOut(duration: 0.3), value: showInsightsCard)
        .background(Color.appBackground)
        .sheet(item: $selectedUserProfile) { user in
            ProfileView(user: user)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = frame.height
                    tabBarVisible.wrappedValue = false
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                keyboardHeight = 0
                tabBarVisible.wrappedValue = true
            }
        }
        .onDisappear {
            tabBarVisible.wrappedValue = true
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

    // MARK: - Content Area

    @ViewBuilder
    private var contentArea: some View {
        switch viewModel.searchPhase {
        case .idle, .typing:
            discoverMasonry
        case .submitted, .streaming, .enhanced:
            resultsView
        }
    }

    // MARK: - Discover Masonry (idle state)

    private var discoverMasonry: some View {
        let users = viewModel.liveResults
        return ScrollView(showsIndicators: false) {
            if users.isEmpty {
                VStack(spacing: Spacing.sm) {
                    Spacer().frame(height: 120)
                    Image(systemName: "sparkle.magnifyingglass")
                        .font(.system(size: 28))
                        .foregroundColor(.appSecondary)
                    Text(viewModel.searchText.isEmpty
                         ? "Discover makers across campus"
                         : "No quick matches — try AI search")
                        .font(.body14)
                        .foregroundColor(.appSecondary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 400)
            } else {
                MasonryLayout(spacing: Spacing.md) {
                    ForEach(users) { user in
                        DiscoverUserCard(
                            user: user,
                            connectionStatus: viewModel.connectionStatus(forUserId: user._id),
                            onTap: { selectedUserProfile = user },
                            onConnect: {
                                Task {
                                    AnalyticsService.shared.track(.connectFromSearch(toUserId: user._id))
                                    _ = await viewModel.sendConnectionRequest(toUserId: user._id)
                                }
                            }
                        )
                    }
                }
                .padding(Spacing.md)
                Spacer().frame(height: 160)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appSurfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Radius.xxl))
        .padding(.top, Spacing.sm)
    }

    // MARK: - Results View

    private var resultsView: some View {
        ScrollView(showsIndicators: false) {
            if !viewModel.displayResults.isEmpty {
                masonryGrid
                    .padding(Spacing.md)
            } else if viewModel.searchPhase == .submitted || viewModel.searchPhase == .streaming {
                masonrySkeleton
                    .padding(Spacing.md)
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
                .frame(maxWidth: .infinity, minHeight: 400)
            }

            Spacer().frame(height: 160)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appSurfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Radius.xxl))
        .padding(.top, Spacing.sm)
        .animation(.easeInOut(duration: 0.3), value: viewModel.searchPhase)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.displayResults.map(\.userId))
    }

    // MARK: - Floating AI Insights Card

    private var aiInsightsCard: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            if viewModel.searchPhase == .submitted {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.appPrimary)
                    .symbolEffect(.pulse, options: .repeating)

                HStack(spacing: Spacing.xs) {
                    Text("Finding people")
                        .font(.body14)
                        .foregroundStyle(Color.appSecondary)
                    TypingDots()
                }
            } else if viewModel.searchPhase == .streaming {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.appPrimary)
                    .symbolEffect(.pulse, options: .repeating)

                if viewModel.streamingThinking.isEmpty {
                    HStack(spacing: Spacing.xs) {
                        Text("Thinking it through")
                            .font(.body14)
                            .foregroundStyle(Color.appSecondary)
                        TypingDots()
                    }
                } else {
                    Text(viewModel.streamingThinking)
                        .font(.body14)
                        .foregroundStyle(Color.appPrimary)
                        .lineLimit(4)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.streamingThinking)
                }
            } else if let thinking = viewModel.aiThinking {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.appPrimary)

                Text(thinking)
                    .font(.body14)
                    .foregroundStyle(Color.appPrimary)
                    .lineLimit(4)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .juntoGlassBackground(cornerRadius: Radius.xxl)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.xxl)
                .stroke(Color.appBorder, lineWidth: 0.5)
        )
    }

    // MARK: - Search Composer Bar

    private var searchComposerBar: some View {
        DiscoverSearchBar(
            text: $viewModel.searchText,
            onSubmit: {
                // Submit/Enter only dismiss the keyboard — AI search is
                // explicitly opted into via the "Search with AI" card.
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            }
        )
    }

    private var bottomSafeArea: CGFloat {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first?.windows.first?.safeAreaInsets.bottom ?? 34
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

    /// Show the "Search with AI" suggestion when the user types a query
    /// that looks like natural language — multi-word, longer than a name.
    /// Hidden during the actual AI search (insights card replaces it).
    private var showAISuggestion: Bool {
        guard viewModel.searchPhase == .typing else { return false }
        let trimmed = viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let wordCount = trimmed.split(whereSeparator: { $0.isWhitespace }).count
        return wordCount >= 3 || trimmed.count >= 18
    }

    // MARK: - AI Search Suggestion

    private var aiSearchSuggestion: some View {
        Button(action: { viewModel.submitSearch() }) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.appPrimary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Search with AI")
                        .font(.bodyMedium)
                        .foregroundStyle(Color.appPrimary)
                    Text("Find people who match what you wrote")
                        .font(.caption12)
                        .foregroundStyle(Color.appSecondary)
                }

                Spacer(minLength: 0)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(width: 28, height: 28)
                    .background(Color.appPrimary, in: RoundedRectangle(cornerRadius: Radius.xl))
            }
            .padding(.leading, Spacing.lg)
            .padding(.trailing, Spacing.md)
            .padding(.vertical, Spacing.md)
            .background(Color.appSurface, in: RoundedRectangle(cornerRadius: Radius.xxl))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.xxl)
                    .stroke(Color.appBorder, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Masonry Grid

    private var masonryGrid: some View {
        MasonryLayout(spacing: Spacing.md) {
            ForEach(viewModel.displayResults, id: \.id) { result in
                if let user = viewModel.userProfiles[result.userId] {
                    let explanation = result.explanation.trimmingCharacters(in: .whitespacesAndNewlines)
                    let hasExplanation = !explanation.isEmpty
                    DiscoverUserCard(
                        user: user,
                        connectionStatus: viewModel.connectionStatus(for: result),
                        explanation: hasExplanation ? explanation : nil,
                        // While in AI results: missing reason = still streaming, show skeleton
                        // (never fall back to the user's profile text in this view).
                        isEnhancing: !hasExplanation,
                        onTap: { selectedUserProfile = user },
                        onConnect: {
                            Task {
                                AnalyticsService.shared.track(.connectFromSearch(toUserId: result.userId))
                                _ = await viewModel.sendConnectionRequest(toUserId: result.userId)
                            }
                        }
                    )
                }
            }
        }
    }

    // MARK: - Masonry Skeleton

    private var masonrySkeleton: some View {
        let heights: [CGFloat] = [160, 190, 175, 200, 165, 180]
        return MasonryLayout(spacing: Spacing.md) {
            ForEach(0..<6, id: \.self) { index in
                DiscoverUserCardSkeleton(height: heights[index])
            }
        }
    }
}
