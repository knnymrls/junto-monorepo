//
//  MessagesView.swift
//  mkrs-world
//
//  Conversation list screen (presented as sheet from top nav bar)
//

import SwiftUI
import Clerk
import Combine

struct MessagesView: View {
    @Environment(\.clerk) private var clerk
    @Environment(\.tabBarVisible) private var tabBarVisible
    @EnvironmentObject private var currentUser: CurrentUserManager
    @StateObject private var viewModel = MessagesListViewModel()
    @State private var selectedConversation: ConversationResponse?
    @State private var showNewConversation = false
    @State private var chatParticipant: UserResponse?
    @State private var chatConversationId: String?
    @State private var showSearch = false
    @FocusState private var searchFocused: Bool
    @State private var selectedUserProfile: UserResponse?

    /// Zoom transition: conversation row → chat detail.
    @Namespace private var chatZoom
    /// Zoom transition: suggested card → that person's profile.
    @Namespace private var profileZoom

    /// Avatar tap is owned by TabBarView (→ side menu), matching the other tabs.
    var onProfileTap: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            header
            if showSearch {
                searchBar
            }

            ZStack {
                Color.appBackground.ignoresSafeArea()

                if viewModel.isLoading && viewModel.conversations.isEmpty {
                    loadingState
                } else {
                    mainList
                }
            }
        }
        .background(Color.appBackground)
        .onReceive(NotificationCenter.default.publisher(for: .composeFABTapped)) { notif in
            if notif.object as? String == Tab.messages.rawValue {
                showNewConversation = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                tabBarVisible.wrappedValue = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                tabBarVisible.wrappedValue = true
            }
        }
        .onDisappear {
            tabBarVisible.wrappedValue = true
        }
        .fullScreenCover(item: $selectedConversation) { conversation in
            if let otherParticipant = conversation.otherParticipant,
               let userId = currentUser.userId {
                ChatDetailView(
                    conversationId: conversation._id,
                    otherParticipant: otherParticipant,
                    currentUserId: userId,
                    isRequest: conversation.isRequest == true
                )
                .environmentObject(currentUser)
                .zoomDestination(id: conversation._id, in: chatZoom)
            }
        }
        .sheet(isPresented: $showNewConversation) {
            if let userId = currentUser.userId {
                NewConversationSheet(currentUserId: userId) { user in
                    showNewConversation = false
                    Task {
                        let conv = try? await ConvexClientManager.shared.fetchConversationBetween(
                            userId1: userId,
                            userId2: user._id
                        )
                        chatConversationId = conv?._id
                        chatParticipant = user
                    }
                }
            }
        }
        .fullScreenCover(item: $chatParticipant) { participant in
            if let userId = currentUser.userId {
                ChatDetailView(
                    conversationId: chatConversationId,
                    otherParticipant: participant,
                    currentUserId: userId
                )
                .environmentObject(currentUser)
                .zoomDestination(id: participant._id, in: chatZoom)
            }
        }
        .fullScreenCover(item: $selectedUserProfile) { user in
            ProfileView(user: user)
                .zoomDestination(id: user._id, in: profileZoom)
        }
        .task {
            if let userId = currentUser.userId {
                viewModel.subscribe(userId: userId)
            }
            AnalyticsService.shared.track(.messagesViewed)
        }
    }

    // MARK: - Header

    /// Mirrors BrandTopNav (avatar + title), but carries two trailing actions:
    /// search (toggles the search field) and a filter menu (All / Inbox /
    /// Requests). Both are 28pt Flex line icons in 40pt tap targets.
    private var header: some View {
        HStack(spacing: Spacing.sm) {
            Button { onProfileTap?() } label: {
                AvatarView(
                    avatarUrl: currentUser.user?.avatarUrl,
                    name: currentUser.user?.name ?? "?",
                    size: 40
                )
            }
            .buttonStyle(.pressableScale(0.9))

            Text("Messages")
                .font(.heading1)
                .foregroundColor(.appPrimary)

            Spacer()

            HStack(spacing: Spacing.xxs) {
                headerIcon("nav.search", tint: showSearch ? .appAccent : .appPrimary) {
                    withAnimation(.easeInOut(duration: 0.2)) { showSearch.toggle() }
                    if showSearch {
                        searchFocused = true
                    } else {
                        viewModel.searchText = ""
                    }
                }
                filterMenu
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.sm)
        .background(Color.appSurface.ignoresSafeArea(edges: .top))
    }

    private func headerIcon(_ name: String, tint: Color = .appPrimary, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            headerIconImage(name, tint: tint)
        }
        .buttonStyle(.pressableScale(0.9))
    }

    private func headerIconImage(_ name: String, tint: Color) -> some View {
        Image(name)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 28, height: 28)
            .foregroundColor(tint)
            .frame(width: 40, height: 40)
            .contentShape(Rectangle())
    }

    /// Filter menu — replaces the old Inbox/Requests segmented tabs. Defaults to
    /// "All" (both inbox + requests shown together); the icon tints accent when
    /// a narrower filter is active.
    private var filterMenu: some View {
        Menu {
            Picker("Filter", selection: $viewModel.filter) {
                ForEach(MessagesFilter.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
        } label: {
            headerIconImage("nav.filter", tint: viewModel.filter == .all ? .appPrimary : .appAccent)
        }
        .buttonStyle(.pressableScale(0.9))
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: Spacing.sm) {
            Image("nav.search")
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
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.sm)
        .background(Color.appSurface)
    }

    // MARK: - Main List

    private var mainList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                let conversations = viewModel.filteredConversations
                let suggested = viewModel.suggestedUsers

                if conversations.isEmpty && suggested.isEmpty {
                    emptyState
                        .padding(.top, 80)
                } else {
                    if !conversations.isEmpty {
                        ForEach(conversations) { conversation in
                            ConversationRow(
                                conversation: conversation,
                                currentUserId: currentUser.userId
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedConversation = conversation
                            }
                            .zoomSource(id: conversation._id, in: chatZoom)
                        }
                    }

                    if !suggested.isEmpty {
                        suggestedSection(users: suggested)
                    }
                }

                Color.clear.frame(height: 80)
            }
        }
        .scrollEdgeFade(top: true, bottom: false)
    }

    // MARK: - Suggested Section

    /// Connections without a thread yet — rendered with the same "People you
    /// should know" card as Discover. Tapping a card opens a chat with them.
    private func suggestedSection(users: [UserResponse]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Suggested")
                .padding(.top, Spacing.lg)

            VStack(spacing: 0) {
                ForEach(users) { user in
                    DiscoverPersonCard(
                        user: user,
                        connectionStatus: .connected,
                        onTap: { selectedUserProfile = user },
                        profileZoomID: AnyHashable(user._id),
                        profileZoomNamespace: profileZoom
                    )
                    .zoomSource(id: user._id, in: profileZoom)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            icon: viewModel.filter == .requests ? "tray" : "bubble.left.and.bubble.right",
            title: viewModel.filter == .requests ? "No message requests" : "No messages yet",
            subtitle: viewModel.filter == .requests
                ? "Message requests from other users will appear here"
                : "Connect with users to start chatting"
        )
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack {
            Spacer()
            ProgressView()
                .tint(.appSecondary)
            Spacer()
        }
    }
}

#Preview {
    MessagesView()
        .environmentObject(CurrentUserManager.shared)
}
