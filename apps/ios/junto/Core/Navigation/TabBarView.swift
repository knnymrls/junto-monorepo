//
//  TabBarView.swift
//  mkrs-world
//
//  Main tab bar navigation: Home · Discover · Junto AI (center) · Messages · Activity
//  + top nav bar with profile avatar
//

import SwiftUI
import Clerk
import Combine

enum Tab: String, CaseIterable {
    case feed
    case discover
    case ai
    case messages
    case notifications

    var iconName: String {
        switch self {
        case .feed: return "tab.home"
        case .discover: return "tab.search"
        case .ai: return "tab.junto"
        case .messages: return "tab.envelope"
        case .notifications: return "tab.heart"
        }
    }

    var selectedIconName: String {
        switch self {
        case .feed: return "tab.home.fill"
        case .discover: return "tab.search"
        case .ai: return "tab.junto"
        case .messages: return "tab.envelope.fill"
        case .notifications: return "tab.heart.fill"
        }
    }

    var title: String {
        switch self {
        case .feed: return "Home"
        case .discover: return "Discover"
        case .ai: return "Ask Junto"
        case .messages: return "Messages"
        case .notifications: return "Activity"
        }
    }

    /// The center brand button (Junto mark) that opens the AI experience.
    var isCenter: Bool { self == .ai }

    /// Whether this tab shows the global compose FAB.
    var hasComposeFAB: Bool {
        switch self {
        case .feed, .discover, .messages: return true
        case .ai, .notifications: return false
        }
    }
}

// Notification posted when a tab's compose FAB is tapped. The object is the
// tab's rawValue so each tab can filter for its own notifications.
extension Notification.Name {
    static let composeFABTapped = Notification.Name("composeFABTapped")
    /// Ask Junto conversations drawer → open a past thread (object = threadId String).
    static let askJuntoOpenThread = Notification.Name("askJuntoOpenThread")
    /// Ask Junto conversations drawer → start a fresh conversation.
    static let askJuntoNewConversation = Notification.Name("askJuntoNewConversation")
}

// Environment key to hide tab bar
struct TabBarVisibilityKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(true)
}

extension EnvironmentValues {
    var tabBarVisible: Binding<Bool> {
        get { self[TabBarVisibilityKey.self] }
        set { self[TabBarVisibilityKey.self] = newValue }
    }
}

struct TabBarView: View {
    @Environment(\.clerk) private var clerk
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var currentUser: CurrentUserManager
    @State private var selectedTab: Tab = .feed
    @State private var isTabBarVisible = true
    @State private var feedbackEvent: EventWithRsvpResponse?
    @State private var hasCheckedFeedback = false

    // Unread counts
    @State private var unreadNotificationCount = 0
    @State private var unreadNotificationCancellable: AnyCancellable?
    @State private var unreadMessageCount = 0
    @State private var unreadMessageCancellable: AnyCancellable?

    // Side menu
    @State private var showSideMenu = false
    @State private var showMyProfile = false
    @State private var showSettings = false
    @State private var showAIConversations = false
    private let menuWidth: CGFloat = 280
    private let aiDrawerWidth: CGFloat = 300

    /// True when either side drawer is open — drives the rounded-page treatment.
    private var drawerOpen: Bool { showSideMenu || showAIConversations }

    // Zoom transition namespace: top-nav avatar → my profile
    @Namespace private var profileZoom

    private let convex = ConvexClientManager.shared

    var body: some View {
        ZStack(alignment: .trailing) {
            // Side menu (sits at right edge, behind content)
            if showSideMenu {
                SideMenuView(
                    isPresented: $showSideMenu,
                    user: currentUser.user,
                    onProfileTap: { showMyProfile = true },
                    onSettingsTap: { showSettings = true },
                    onSignOutTap: {
                        OnboardingViewModel.clearAllStorage()
                        Task { try? await clerk.signOut() }
                    }
                )
                .frame(width: menuWidth)
            }

            // Ask Junto conversations drawer (sits at right edge, behind content)
            if showAIConversations, let uid = currentUser.userId {
                AskJuntoThreadsDrawer(
                    userId: uid,
                    onSelect: { id in
                        NotificationCenter.default.post(name: .askJuntoOpenThread, object: id)
                        withAnimation(.easeInOut(duration: 0.25)) { showAIConversations = false }
                    },
                    onNew: {
                        NotificationCenter.default.post(name: .askJuntoNewConversation, object: nil)
                        withAnimation(.easeInOut(duration: 0.25)) { showAIConversations = false }
                    }
                )
                .frame(width: aiDrawerWidth)
            }

            // Main content (slides left to reveal menu)
            ZStack(alignment: .bottom) {
                Group {
                    switch selectedTab {
                    case .feed:
                        VStack(spacing: 0) {
                            feedTopNav
                            FeedView()
                        }
                    case .discover:
                        // Discover owns its own NavigationStack + header so the
                        // Events / People / Search pages push in from the right.
                        DiscoverView(
                            onAvatarTap: { showMyProfile = true },
                            profileZoomNamespace: profileZoom
                        )
                    case .ai:
                        // Ask Junto owns its own header (avatar + title + history),
                        // empty state, conversation, and composer.
                        AskJuntoView(
                            onProfileTap: { withAnimation(.easeInOut(duration: 0.25)) { showSideMenu.toggle() } },
                            onOpenConversations: { withAnimation(.easeInOut(duration: 0.25)) { showAIConversations = true } }
                        )
                    case .messages:
                        VStack(spacing: 0) {
                            defaultTopNav(.messages)
                            MessagesView()
                        }
                    case .notifications:
                        VStack(spacing: 0) {
                            defaultTopNav(.notifications)
                            NotificationsView()
                        }
                    }
                }
                .environment(\.tabBarVisible, $isTabBarVisible)
                .ignoresSafeArea(.keyboard, edges: .bottom)

                if isTabBarVisible {
                    VStack(spacing: 0) {
                        LinearGradient(
                            colors: [Color.appBackground.opacity(0), Color.appBackground],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 24)
                        .allowsHitTesting(false)

                        HStack(spacing: 24) {
                            ForEach(Tab.allCases, id: \.self) { tab in
                                TabButton(
                                    tab: tab,
                                    isSelected: selectedTab == tab,
                                    hasNotification: (tab == .notifications && unreadNotificationCount > 0) || (tab == .messages && unreadMessageCount > 0),
                                    action: {
                                        selectedTab = tab
                                    }
                                )
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, Spacing.xs)
                        .padding(.bottom, Spacing.xxs)
                        .background(Color.appSurface.ignoresSafeArea(edges: .bottom))
                    }
                    .transition(.move(edge: .bottom))
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if isTabBarVisible, selectedTab.hasComposeFAB {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        NotificationCenter.default.post(
                            name: .composeFABTapped,
                            object: selectedTab.rawValue
                        )
                    }) {
                        Image("action.add")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .foregroundColor(.appOnAccent)
                            .frame(width: 64, height: 52)
                            .background(Color.appPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.xxl))
                    }
                    .buttonStyle(.pressableScale)
                    .padding(.trailing, Spacing.lg)
                    .padding(.bottom, 72)
                }
            }
            .overlay {
                if showSideMenu || showAIConversations {
                    Color.black.opacity(0.001)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showSideMenu = false
                                showAIConversations = false
                            }
                        }
                }
            }
            // Round the content like a natural iOS page sitting on the drawer.
            // A mask that ignores the safe area rounds the FULL screen (incl. the
            // top/bottom safe areas) without shifting any layout, so no black gaps.
            .mask {
                RoundedRectangle(cornerRadius: drawerOpen ? 40 : 0, style: .continuous)
                    .ignoresSafeArea()
            }
            // Always-present so it rounds with the card instead of opacity-fading
            // in (lineWidth 0 when closed keeps it off the full-screen edges).
            .overlay {
                RoundedRectangle(cornerRadius: drawerOpen ? 40 : 0, style: .continuous)
                    .stroke(Color.appBorder, lineWidth: drawerOpen ? 1 : 0)
                    .ignoresSafeArea()
            }
            // Shadow only in light mode — on the dark surface it read as a black smudge.
            .shadow(
                color: .black.opacity((drawerOpen && colorScheme == .light) ? 0.12 : 0),
                radius: 16, x: 0, y: 2
            )
            .offset(x: showSideMenu ? -menuWidth : (showAIConversations ? -aiDrawerWidth : 0))
        }
        // Profile sheet
        .fullScreenCover(isPresented: $showMyProfile) {
            if let user = currentUser.user {
                ProfileView(user: user)
                    .zoomDestination(id: user._id, in: profileZoom)
            }
        }
        // Settings sheet
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(currentUser)
                .environmentObject(ThemeManager.shared)
        }
        // Event feedback prompt
        .sheet(item: $feedbackEvent) { event in
            EventFeedbackSheet(
                event: event,
                onComplete: { feedbackEvent = nil },
                onSkip: { feedbackEvent = nil }
            )
            .presentationDragIndicator(.visible)
        }
        .task {
            await checkForFeedbackPrompt()

            if let userId = currentUser.userId {
                unreadNotificationCancellable = convex.subscribeUnreadCount(userId: userId)
                    .receive(on: DispatchQueue.main)
                    .sink(
                        receiveCompletion: { _ in },
                        receiveValue: { count in self.unreadNotificationCount = count }
                    )

                unreadMessageCancellable = convex.subscribeUnreadMessageCount(userId: userId)
                    .receive(on: DispatchQueue.main)
                    .sink(
                        receiveCompletion: { _ in },
                        receiveValue: { count in self.unreadMessageCount = count }
                    )
            }
        }
    }

    // MARK: - Top navs

    private var feedTopNav: some View {
        BrandTopNav(
            avatarUrl: currentUser.user?.avatarUrl,
            name: currentUser.user?.name ?? "?",
            center: .wordmark("Junto"),
            onAvatarTap: { showMyProfile = true },
            trailingIcon: "nav.menu",
            onTrailingTap: { withAnimation(.easeInOut(duration: 0.25)) { showSideMenu.toggle() } },
            profileZoomID: currentUser.user.map { AnyHashable($0._id) },
            profileZoomNamespace: profileZoom
        )
    }

    private func defaultTopNav(_ tab: Tab) -> some View {
        TopNavBar(
            title: tab.title,
            avatarUrl: currentUser.user?.avatarUrl,
            avatarName: currentUser.user?.name ?? "?",
            onProfileTap: { withAnimation(.easeInOut(duration: 0.25)) { showSideMenu.toggle() } }
        )
    }

    private func checkForFeedbackPrompt() async {
        guard !hasCheckedFeedback else { return }
        hasCheckedFeedback = true

        guard let userId = currentUser.userId else { return }

        do {
            let needsFeedback = try await convex.fetchEventsNeedingFeedback(userId: userId)

            if let first = needsFeedback.first {
                feedbackEvent = first
            }
        } catch {
            print("Feedback check error: \(error)")
        }
    }
}

struct TabButton: View {
    let tab: Tab
    let isSelected: Bool
    var hasNotification: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if tab.isCenter {
                // Center brand button: the Junto mark in a pill, opens the AI experience.
                Image(tab.iconName)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 28, height: 28)
                    .foregroundColor(.appPrimary)
                    .frame(width: 60, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.xl)
                            .fill(Color.appSurfaceSecondary)
                    )
            } else {
                Image(isSelected ? tab.selectedIconName : tab.iconName)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .foregroundColor(isSelected ? .appPrimary : .appSecondary)
                    .overlay(alignment: .topTrailing) {
                        if hasNotification {
                            Circle()
                                .fill(.red)
                                .frame(width: 8, height: 8)
                                .overlay(
                                    Circle()
                                        .stroke(Color.appSurface, lineWidth: 2)
                                )
                                .offset(x: 2, y: 0)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
            }
        }
        .buttonStyle(.pressableScale(0.9))
    }
}

#Preview {
    TabBarView()
        .environmentObject(ThemeManager.shared)
        .environmentObject(CurrentUserManager.shared)
}
