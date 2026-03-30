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
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    // Content
                    if viewModel.isLoading && viewModel.posts.isEmpty {
                        loadingState
                    } else if viewModel.posts.isEmpty {
                        emptyState
                    } else {
                        feedList
                    }
                }

                // Floating action button for new post
                Button(action: { showComposer = true }) {
                    Image("action.add")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(.appOnAccent)
                        .padding(Spacing.md)
                        .background(Color.appPrimary)
                        .clipShape(Circle())
                }
                .padding(.trailing, Spacing.lg)
                .padding(.bottom, 72) // Above tab bar
            }
            .background(Color.appBackground)
            .navigationBarHidden(true)
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

    // MARK: - Composer Row

    private var composerRow: some View {
        ComposerRow(
            avatarUrl: currentUser.user?.avatarUrl,
            name: currentUser.user?.name ?? "?",
            onTap: { showComposer = true }
        )
    }

    // MARK: - Feed List

    private var feedList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                // Composer row at top
                composerRow

                Rectangle()
                    .fill(Color.appDivider)
                    .frame(height: hairline)

                // Suggested matches carousel
                suggestedMatchesCarousel

                Rectangle()
                    .fill(Color.appDivider)
                    .frame(height: hairline)

                // Posts
                ForEach(Array(viewModel.posts.enumerated()), id: \.element.id) { index, post in
                    Button(action: { selectedPost = post }) {
                        FeedPostCard(
                            post: post,
                            connectionStatus: viewModel.connectionStatus(userId: post.authorId),
                            isOwnPost: viewModel.isAuthor(of: post),
                            onConnectTap: {
                                Task {
                                    await viewModel.sendConnectionRequest(toUserId: post.authorId, source: .feed)
                                    AnalyticsService.shared.track(.connectFromPost(postId: post._id, category: post.categoryType.rawValue))
                                }
                            },
                            onDisconnectTap: {
                                Task { await viewModel.handleDisconnect(userId: post.authorId) }
                            },
                            onReplyTap: {
                                selectedPost = post
                            },
                            onEditTap: {
                                editingPost = post
                            },
                            onDeleteTap: {
                                Task {
                                    _ = await viewModel.deletePost(post._id)
                                    await viewModel.refresh()
                                }
                            },
                            onReportTap: {
                                reportingPost = post
                            },
                            onAuthorTap: {
                                if let author = post.author {
                                    selectedUserProfile = author
                                }
                            },
                            onMentionTap: { name in
                                Task {
                                    if let user = try? await ConvexClientManager.shared.fetchUserByName(name: name) {
                                        selectedUserProfile = user
                                    }
                                }
                            }
                        )
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        // Load more when near bottom (2 posts before end)
                        if index >= viewModel.posts.count - 2 {
                            Task {
                                await viewModel.loadMorePosts()
                            }
                        }
                    }

                    Rectangle()
                        .fill(Color.appDivider)
                        .frame(height: hairline)
                }

                // Loading more indicator
                if viewModel.isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(.appSecondary)
                            .padding(.vertical, Spacing.lg)
                        Spacer()
                    }
                }

                // Bottom padding for tab bar
                Color.clear.frame(height: 80)
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 0) {
            composerRow

            Rectangle()
                .fill(Color.appDivider)
                .frame(height: hairline)

            suggestedMatchesCarousel

            Rectangle()
                .fill(Color.appDivider)
                .frame(height: hairline)

            Spacer()

            VStack(spacing: Spacing.lg) {
                Image(systemName: "square.stack.3d.up.slash")
                    .font(.system(size: 48))
                    .foregroundColor(.appSecondary)

                Text("No posts yet")
                    .font(.heading3Regular)
                    .foregroundColor(.appPrimary)

                Text("Be the first to share something")
                    .font(.body14)
                    .foregroundColor(.appSecondary)
            }

            Spacer()
        }
    }

    // MARK: - Suggested Matches Carousel

    private var suggestedMatchesCarousel: some View {
        SuggestedMatchCarousel(
            matches: viewModel.suggestedMatches,
            connectionStatusFor: { viewModel.connectionStatus(userId: $0) },
            onConnectTap: { match in
                Task {
                    await viewModel.sendConnectionRequest(toUserId: match._id, source: .match)
                }
            },
            onWithdrawTap: { match in
                Task {
                    await viewModel.withdrawConnectionRequest(toUserId: match._id)
                }
            },
            onCardTap: { match in
                selectedUserProfile = match.toUserResponse()
            }
        )
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
