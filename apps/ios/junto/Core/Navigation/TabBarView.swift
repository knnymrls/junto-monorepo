//
//  TabBarView.swift
//  mkrs-world
//
//  Main tab bar navigation (5 tabs) + top nav bar with profile avatar
//

import SwiftUI
import Clerk
import Combine

enum Tab: String, CaseIterable {
    case feed
    case events
    case search
    case messages
    case notifications

    var iconName: String {
        switch self {
        case .feed: return "tab.home"
        case .events: return "tab.event"
        case .search: return "tab.search"
        case .messages: return "tab.envelope"
        case .notifications: return "tab.heart"
        }
    }

    var selectedIconName: String {
        switch self {
        case .feed: return "tab.home.fill"
        case .events: return "tab.event.fill"
        case .search: return "tab.search"
        case .messages: return "tab.envelope.fill"
        case .notifications: return "tab.heart.fill"
        }
    }

    var title: String {
        switch self {
        case .feed: return "Feed"
        case .events: return "Events"
        case .search: return "Search"
        case .messages: return "Messages"
        case .notifications: return "Activity"
        }
    }

    var usesSystemIcon: Bool {
        false
    }

    /// Whether this tab shows the global compose FAB.
    var hasComposeFAB: Bool {
        switch self {
        case .feed, .events, .messages: return true
        case .search, .notifications: return false
        }
    }
}

// Notification posted when a tab's compose FAB is tapped. The object is the
// tab's rawValue so each tab can filter for its own notifications.
extension Notification.Name {
    static let composeFABTapped = Notification.Name("composeFABTapped")
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
    private let menuWidth: CGFloat = 280

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

            // Main content (slides left to reveal menu)
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    TopNavBar(
                        title: selectedTab.title,
                        avatarUrl: currentUser.user?.avatarUrl,
                        avatarName: currentUser.user?.name ?? "?",
                        onProfileTap: { withAnimation(.easeInOut(duration: 0.25)) { showSideMenu.toggle() } }
                    )

                    Group {
                        switch selectedTab {
                        case .feed:
                            FeedView()
                        case .events:
                            EventsView()
                        case .search:
                            SearchView()
                        case .messages:
                            MessagesView()
                        case .notifications:
                            NotificationsView()
                        }
                    }
                    .environment(\.tabBarVisible, $isTabBarVisible)
                }
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
                    .padding(.trailing, Spacing.lg)
                    .padding(.bottom, 72)
                }
            }
            .overlay {
                if showSideMenu {
                    Color.black.opacity(0.001)
                        .ignoresSafeArea()
                        .onTapGesture { withAnimation(.easeInOut(duration: 0.25)) { showSideMenu = false } }
                }
            }
            .offset(x: showSideMenu ? -menuWidth : 0)
        }
        // Profile sheet
        .sheet(isPresented: $showMyProfile) {
            if let user = currentUser.user {
                ProfileView(user: user)
                    .presentationDragIndicator(.visible)
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

    private var isSearchTab: Bool { tab == .search }

    var body: some View {
        Button(action: action) {
            if isSearchTab {
                Image(tab.iconName)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .foregroundColor(.appSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.md)
                            .fill(Color.appSurfaceSecondary)
                    )
            } else if tab.usesSystemIcon {
                Image(systemName: isSelected ? tab.selectedIconName : tab.iconName)
                    .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .appPrimary : .appSecondary)
                    .frame(width: 24, height: 24)
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
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
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
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
            }
        }
    }
}

#Preview {
    TabBarView()
        .environmentObject(ThemeManager.shared)
        .environmentObject(CurrentUserManager.shared)
}
