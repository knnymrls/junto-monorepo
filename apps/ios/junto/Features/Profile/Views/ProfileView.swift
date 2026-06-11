//
//  ProfileView.swift
//  junto
//
//  Profile page — PostDetailTopNav (circle back + share), the hero block
//  (ProfileHeaderView), and animated underline tabs: About · Work · Vouches ·
//  Activity. Reads as the same surface family as the post/event detail pages.
//

import SwiftUI
import Combine

enum ProfileTab: String, CaseIterable {
    case about = "About"
    case work = "Work"
    case vouches = "Vouches"
    case activity = "Activity"
}

struct ProfileView: View {
    @State private var user: UserResponse
    @EnvironmentObject private var currentUser: CurrentUserManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: ProfileTab = .about
    @State private var connectionStatus: ConnectionStatus = .none
    @State private var connectionCount = 0
    @State private var postCount = 0
    @State private var vouches: [VouchResponse] = []
    @State private var context: ProfileContextResponse?
    @State private var isActioning = false
    @State private var hasVouched = false
    @State private var showVouchSheet = false
    @State private var showEditSheet = false
    @State private var showShareSheet = false
    @State private var showChat = false
    @State private var postsCancellable: AnyCancellable?

    @Namespace private var tabNamespace

    private var hairline: CGFloat { 1 / UIScreen.main.scale }

    init(user: UserResponse) {
        _user = State(initialValue: user)
    }

    var isSelf: Bool {
        currentUser.userId == user._id
    }

    /// Vocation bucket for the Work tab's starter ideas — major first, then
    /// derived skill categories.
    private var vocation: SkillCategory? {
        for major in context?.majorNames ?? [] {
            if let match = SkillCategory.match(major) { return match }
        }
        for category in user.skillCategories ?? [] {
            if let match = SkillCategory.match(category) { return match }
        }
        return nil
    }

    var body: some View {
        VStack(spacing: 0) {
            PostDetailTopNav(
                title: "Profile",
                onBack: { dismiss() },
                onShare: { showShareSheet = true }
            )

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ProfileHeaderView(
                        user: user,
                        context: context,
                        connectionStatus: connectionStatus,
                        connectionCount: connectionCount,
                        vouchCount: vouches.count,
                        postCount: postCount,
                        hasVouched: hasVouched,
                        isSelf: isSelf,
                        isActioning: $isActioning,
                        onEdit: { showEditSheet = true },
                        onVouch: { showVouchSheet = true },
                        onMessage: { showChat = true },
                        onConnect: sendRequest,
                        onAccept: acceptRequest,
                        onTapPosts: { selectTab(.activity) },
                        onTapVouches: { selectTab(.vouches) }
                    )

                    tabBar
                        .padding(.top, Spacing.xl)

                    tabContent
                        .padding(.top, Spacing.lg)

                    Color.clear.frame(height: Spacing.huge)
                }
            }
            .scrollEdgeFade(top: true, bottom: false)
        }
        .background(Color.appBackground)
        .fullScreenCover(isPresented: $showEditSheet) {
            EditProfileSheet(user: user) { updated in
                user = updated
            }
        }
        // The system share sheet stays a sheet — it's a UIKit activity panel,
        // not a page.
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [shareText])
        }
        .fullScreenCover(isPresented: $showChat) {
            if let userId = currentUser.userId {
                ChatDetailView(
                    conversationId: nil,
                    otherParticipant: user,
                    currentUserId: userId
                )
            }
        }
        .fullScreenCover(isPresented: $showVouchSheet) {
            VouchSheet(
                userName: user.name,
                fromUserId: currentUser.userId ?? "",
                toUserId: user._id,
                onVouched: {
                    hasVouched = true
                    Task { await loadVouches() }
                }
            )
        }
        .task {
            AnalyticsService.shared.track(.profileViewed(userId: user._id))
            subscribePostCount()
            // Independent loads run concurrently — one slow or failing call
            // can never blank the others (counts, badge, campus line).
            async let connections: Void = loadConnectionData()
            async let vouchList: Void = loadVouches()
            async let profileContext: Void = loadContext()
            _ = await (connections, vouchList, profileContext)
        }
        .onDisappear { postsCancellable?.cancel() }
    }

    // MARK: - Share

    private var shareText: String {
        isSelf
            ? "Check out my profile on Junto! https://onjunto.com"
            : "Check out \(user.name) on Junto! https://onjunto.com"
    }

    // MARK: - Tab Bar

    private func selectTab(_ tab: ProfileTab) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            selectedTab = tab
        }
    }

    private var tabBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(ProfileTab.allCases, id: \.self) { tab in
                    tabButton(tab)
                }
            }
            .padding(.horizontal, Spacing.lg)

            Rectangle()
                .fill(Color.appDivider)
                .frame(height: hairline)
        }
    }

    private func tabButton(_ tab: ProfileTab) -> some View {
        Button(action: { selectTab(tab) }) {
            Text(tab.rawValue)
                .font(selectedTab == tab ? .bodySemibold : .body14)
                .foregroundColor(selectedTab == tab ? .appPrimary : .appSecondary)
                .padding(.vertical, Spacing.md)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .bottom) {
                    if selectedTab == tab {
                        Capsule()
                            .fill(Color.appPrimary)
                            .frame(width: 44, height: 3)
                            .matchedGeometryEffect(id: "profile.tab.underline", in: tabNamespace)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .about:
            AboutTabView(
                user: user,
                context: context,
                isSelf: isSelf,
                onEdit: { showEditSheet = true }
            )
        case .work:
            PortfolioTabView(userId: user._id, isSelf: isSelf, vocation: vocation)
        case .vouches:
            VouchesTabView(userId: user._id)
        case .activity:
            ActivityTabView(
                userId: user._id,
                userName: user.name,
                isSelf: isSelf,
                connectionCount: connectionCount,
                connectionStatus: displayConnectionStatus,
                onConnect: sendRequest
            )
        }
    }

    /// Viewer ↔ profile connection state in the feed's badge vocabulary.
    private var displayConnectionStatus: ConnectionDisplayStatus {
        switch connectionStatus {
        case .connected: return .connected
        case .pendingSent, .pendingReceived: return .pending
        case .none: return .none
        }
    }

    // MARK: - Data Loading

    private func loadContext() async {
        do {
            context = try await ConvexClientManager.shared.fetchProfileContext(userId: user._id)
        } catch {
            print("ProfileView: Failed to fetch profile context: \(error)")
        }
    }

    private func subscribePostCount() {
        postsCancellable = ConvexClientManager.shared.subscribePostsByAuthor(authorId: user._id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { posts in
                    withAnimation(.easeOut(duration: 0.2)) { postCount = posts.count }
                }
            )
    }

    private func loadConnectionData() async {
        // Load connection count
        do {
            let connections = try await ConvexClientManager.shared.fetchConnections(userId: user._id)
            connectionCount = connections.count
        } catch {
            print("ProfileView: Failed to fetch connections: \(error)")
        }

        // Load connection status if not self
        guard let userId = currentUser.userId, userId != user._id else { return }
        do {
            connectionStatus = try await ConvexClientManager.shared.getConnectionStatus(
                fromUserId: userId,
                toUserId: user._id
            )
        } catch {
            print("ProfileView: Connection status error: \(error)")
        }
        // Load vouch status if connected and not self
        if connectionStatus == .connected {
            do {
                hasVouched = try await ConvexClientManager.shared.hasVouched(
                    fromUserId: userId,
                    toUserId: user._id
                )
            } catch {
                print("ProfileView: Has vouched check error: \(error)")
            }
        }

    }

    private func loadVouches() async {
        do {
            vouches = try await ConvexClientManager.shared.fetchVouches(userId: user._id)
        } catch {
            print("ProfileView: Failed to fetch vouches: \(error)")
        }
    }

    private func sendRequest() {
        guard let userId = currentUser.userId else { return }
        isActioning = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        Task {
            do {
                _ = try await ConvexClientManager.shared.sendConnectionRequest(
                    requesterId: userId,
                    accepterId: user._id
                )
                withAnimation(.easeInOut(duration: 0.2)) { connectionStatus = .pendingSent }
                ConnectionEvents.post(userId: user._id, status: .pendingSent)
            } catch {
                print("Send connection request error: \(error)")
            }
            isActioning = false
        }
    }

    private func acceptRequest() {
        guard let userId = currentUser.userId else { return }
        isActioning = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        Task {
            do {
                _ = try await ConvexClientManager.shared.acceptConnectionRequestByUsers(
                    currentUserId: userId,
                    otherUserId: user._id
                )
                withAnimation(.easeInOut(duration: 0.2)) { connectionStatus = .connected }
                ConnectionEvents.post(userId: user._id, status: .connected)
            } catch {
                print("Accept connection request error: \(error)")
            }
            isActioning = false
        }
    }
}
