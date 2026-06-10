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
    @State private var selectedEvent: EventWithRsvpResponse?
    // Zoom transition namespace: post card → post detail
    @Namespace private var postZoom
    // Zoom transition namespace: author avatar → profile
    @Namespace private var profileZoom
    // Zoom transition namespace: event card → event detail
    @Namespace private var eventZoom
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
        .fullScreenCover(item: $selectedPost) { post in
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
            .zoomDestination(id: post._id, in: postZoom)
        }
        .fullScreenCover(item: $selectedUserProfile) { user in
            ProfileView(user: user)
                .zoomDestination(id: user._id, in: profileZoom)
        }
        .fullScreenCover(item: $selectedEvent) { event in
            EventDetailView(event: event)
                .zoomDestination(id: event._id, in: eventZoom)
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
                if ProcessInfo.processInfo.environment["JUNTO_PREVIEW_COMPOSER"] == "1" {
                    showComposer = true
                }
                if ProcessInfo.processInfo.environment["JUNTO_PREVIEW_POST"] == "1",
                   let first = viewModel.feedItems.first(where: { $0.post != nil })?.post {
                    selectedPost = first
                }
                if ProcessInfo.processInfo.environment["JUNTO_PREVIEW_EVENT"] == "1",
                   let ev = viewModel.feedItems.first(where: { $0.event != nil })?.event {
                    selectEvent(ev)
                }
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
        // Top fade only — the bottom fade is handled by the tab bar gradient.
        .scrollEdgeFade(top: true, bottom: false)
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
                },
                profileZoomID: post.author.map { AnyHashable($0._id) },
                profileZoomNamespace: profileZoom
            )
            .zoomSource(id: post._id, in: postZoom)
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
                onAuthorTap: { selectedUserProfile = match.toUserResponse() },
                profileZoomID: AnyHashable(match._id),
                profileZoomNamespace: profileZoom
            )
        case .event(let event):
            FeedEventCard(
                event: event,
                tags: item.displayTags,
                onCardTap: { selectEvent(event) }
            )
            .zoomSource(id: event._id, in: eventZoom)
        case .digest(let digest):
            FeedNoticeCard(
                icon: "sparkles",
                title: "This week on campus",
                subtitle: digestSubtitle(digest)
            )
        case .vouch(let vouch):
            FeedVouchCard(vouch: vouch)
        case .momentum(let momentum):
            FeedNoticeCard(
                icon: "person.2",
                title: "Campus momentum",
                subtitle: "\(momentum.connectionsThisWeek) connection\(momentum.connectionsThisWeek == 1 ? "" : "s") made this week"
            )
        case .milestone(let milestone):
            FeedNoticeCard(
                icon: "trophy",
                title: "You've reached \(milestone.count) connections",
                subtitle: "Your network is growing"
            )
        case .prompt(let prompt):
            FeedNoticeCard(
                icon: "square.and.pencil",
                title: prompt.text,
                subtitle: "Tap to post",
                onTap: { showComposer = true }
            )
        case .caughtUp:
            FeedCaughtUpCard()
        case .none:
            EmptyView()
        }
    }

    /// Builds the digest subtitle, dropping zero counts (e.g. "5 new makers · 2 events").
    private func digestSubtitle(_ d: DigestFeedResponse) -> String {
        var parts: [String] = []
        if d.newMakers > 0 { parts.append("\(d.newMakers) new maker\(d.newMakers == 1 ? "" : "s")") }
        if d.newAsks > 0 { parts.append("\(d.newAsks) ask\(d.newAsks == 1 ? "" : "s")") }
        if d.upcomingEvents > 0 { parts.append("\(d.upcomingEvents) event\(d.upcomingEvents == 1 ? "" : "s")") }
        return parts.joined(separator: " · ")
    }

    // MARK: - Event Selection

    private func selectEvent(_ event: EventResponse) {
        #if DEBUG
        if ProcessInfo.processInfo.environment["JUNTO_PREVIEW_FEED"] == "1" {
            // No backend in the preview rig — route the feed event (and its
            // cover) straight into the detail.
            selectedEvent = EventWithRsvpResponse.preview(from: event)
            return
        }
        #endif
        Task {
            if let full = try? await ConvexClientManager.shared.fetchEvent(id: event._id) {
                await MainActor.run { selectedEvent = full }
            }
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
