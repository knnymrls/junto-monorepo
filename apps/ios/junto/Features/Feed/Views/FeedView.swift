//
//  FeedView.swift
//  mkrs-world
//
//  Main feed screen
//

import SwiftUI
import Clerk

struct FeedView: View {
    @Environment(\.clerk) private var clerk
    @EnvironmentObject private var currentUser: CurrentUserManager
    @StateObject private var viewModel = FeedViewModel()
    @State private var showComposer = false
    @State private var selectedPost: PostResponse?
    @State private var selectedUserProfile: UserResponse?
    @State private var editingPost: PostResponse?
    @State private var chatParticipant: UserResponse?
    @State private var chatConversationId: String?
    @State private var reportingPost: PostResponse?
    // Hairline thickness for consistent 1px dividers
    private var hairline: CGFloat {
        1 / UIScreen.main.scale
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.isLoading && viewModel.feedItems.isEmpty {
                    loadingState
                } else {
                    feedScroll
                }
            }
            .background(Color.appBackground)
            .navigationBarHidden(true)
            .onReceive(NotificationCenter.default.publisher(for: .composeFABTapped)) { notif in
                if notif.object as? String == Tab.feed.rawValue {
                    showComposer = true
                }
            }
        }
        .sheet(isPresented: $showComposer) {
            PostComposerView(viewModel: viewModel)
        }
        .onChange(of: showComposer) { _, isShowing in
            if isShowing {
                AnalyticsService.shared.track(.composerOpened)
            }
        }
        .sheet(item: $editingPost) { post in
            PostComposerView(viewModel: viewModel, editingPost: post)
        }
        .sheet(item: $selectedPost) { post in
            ImageViewerRoot {
                FeedPostSheet(
                    post: post,
                    currentUserId: currentUser.userId,
                    connectedUserIds: viewModel.connectedUserIds,
                    connectionStatus: viewModel.connectionStatus(userId: post.authorId),
                    onConnectTap: {
                        Task {
                            await viewModel.sendConnectionRequest(toUserId: post.authorId, source: .postDetail)
                        }
                    },
                    onDisconnectTap: {
                        Task { await viewModel.handleDisconnect(userId: post.authorId) }
                    },
                    onEditPostTap: {
                        editingPost = post
                    }
                )
            }
        }
        .sheet(item: $selectedUserProfile) { user in
            ProfileView(user: user)
        }
        .sheet(item: $chatParticipant) { participant in
            if let userId = currentUser.userId {
                ChatDetailView(
                    conversationId: chatConversationId,
                    otherParticipant: participant,
                    currentUserId: userId
                )
            }
        }
        .sheet(item: $reportingPost) { post in
            if let userId = currentUser.userId {
                ReportPostSheet(postId: post._id, reporterId: userId)
            }
        }
        .task {
            #if DEBUG
            if ProcessInfo.processInfo.environment["JUNTO_PREVIEW_FEED"] == "1" {
                viewModel.currentUser = currentUser.user
                viewModel.feedItems = FeedItemResponse.previewItems
                viewModel.hasMorePosts = false
                return
            }
            #endif
            if let user = currentUser.user {
                viewModel.currentUser = user
                await viewModel.bootstrap(userId: user._id)
            }
        }
        .onChange(of: currentUser.user?._id) { _, newUserId in
            if let user = currentUser.user, newUserId != nil {
                viewModel.currentUser = user
            }
        }
        .onAppear {
            AnalyticsService.shared.trackFeedSession()
        }
    }

    // MARK: - Feed Scroll Container

    private var feedScroll: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(Array(viewModel.feedItems.enumerated()), id: \.element.id) { index, item in
                    feedItemRow(item)
                        .onAppear {
                            // Load more when near the bottom (2 items before end)
                            if index >= viewModel.feedItems.count - 2 {
                                Task { await viewModel.loadMorePosts() }
                            }
                        }

                    Rectangle()
                        .fill(Color.appDivider)
                        .frame(height: hairline)
                }

                if viewModel.isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(.appSecondary)
                            .padding(.vertical, Spacing.lg)
                        Spacer()
                    }
                } else if viewModel.feedItems.isEmpty || !viewModel.hasMorePosts {
                    // End of feed — also serves as the empty state when there are no items
                    FeedEndState()
                }

                // Bottom padding so the last row / end state clears the floating tab bar
                Color.clear.frame(height: 110)
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
        .overlay(alignment: .top) {
            // Top fade — mirrors the bottom fade above the tab bar; content
            // dissolves into the background as it scrolls up under the nav.
            LinearGradient(
                colors: [Color.appBackground, Color.appBackground.opacity(0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 24)
            .allowsHitTesting(false)
        }
    }

    // MARK: - Feed Item Row
    // Post → Ask card, Match → Match card (FeedCard). Event still uses the
    // placeholder until the Opportunity card is designed.

    @ViewBuilder
    private func feedItemRow(_ item: FeedItemResponse) -> some View {
        switch item.content {
        case .post(let post):
            FeedCard(
                item: item,
                connectionStatus: viewModel.connectionStatus(userId: post.authorId),
                isOwnItem: post.authorId == currentUser.userId,
                onConnectTap: {
                    Task { await viewModel.sendConnectionRequest(toUserId: post.authorId, source: .feed) }
                },
                onDisconnectTap: {
                    Task { await viewModel.handleDisconnect(userId: post.authorId) }
                },
                onCardTap: { selectedPost = post },
                onAuthorTap: { selectedUserProfile = post.author },
                onMentionTap: { name in
                    Task {
                        if let user = await viewModel.fetchUserByName(name) {
                            selectedUserProfile = user
                        }
                    }
                }
            )
        case .match(let match):
            FeedCard(
                item: item,
                connectionStatus: viewModel.connectionStatus(userId: match._id),
                isOwnItem: false,
                onConnectTap: {
                    Task { await viewModel.sendConnectionRequest(toUserId: match._id, source: .match) }
                },
                onDisconnectTap: {
                    Task { await viewModel.handleDisconnect(userId: match._id) }
                },
                onCardTap: { selectedUserProfile = match.toUserResponse() },
                onAuthorTap: { selectedUserProfile = match.toUserResponse() }
            )
        case .event(let event):
            FeedEventCard(event: event, tags: item.displayTags)
        case .none:
            EmptyView()
        }
    }

    // MARK: - Loading State

    private var loadingState: some View {
        ScrollView(showsIndicators: false) {
            FeedSkeleton()
        }
    }
}

#Preview {
    FeedView()
        .environmentObject(CurrentUserManager.shared)
}
