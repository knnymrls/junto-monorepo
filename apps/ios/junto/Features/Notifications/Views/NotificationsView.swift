//
//  NotificationsView.swift
//  mkrs-world
//
//  In-app notification list (presented as sheet from top nav bar)
//

import SwiftUI
import Combine
import Clerk

struct NotificationsView: View {
    @Environment(\.clerk) private var clerk
    @EnvironmentObject private var currentUser: CurrentUserManager
    @StateObject private var viewModel = NotificationsViewModel()
    @State private var selectedPost: PostResponse?
    @State private var selectedUserProfile: UserResponse?
    @State private var selectedEvent: EventWithRsvpResponse?
    @State private var showComposer = false
    @State private var chatParticipant: UserResponse?
    @State private var chatConversationId: String?
    @State private var showPreferences = false

    /// Avatar tap is owned by TabBarView (→ side menu), matching the other tabs.
    var onProfileTap: (() -> Void)? = nil

    // Zoom transition namespace: notification sender avatar → profile
    @Namespace private var profileZoom
    // Zoom transition namespace: event notification row → event detail
    @Namespace private var eventZoom

    private var hairline: CGFloat { 1 / UIScreen.main.scale }

    var body: some View {
        VStack(spacing: 0) {
            header

            ZStack {
                Color.appBackground.ignoresSafeArea()

                if viewModel.isLoading && viewModel.notifications.isEmpty {
                    loadingState
                } else if viewModel.notifications.isEmpty {
                    EmptyStateView(
                        icon: "bell",
                        title: "No notifications yet",
                        subtitle: "You'll be notified when someone connects, comments, or mentions you"
                    )
                } else {
                    notificationList
                }
            }
        }
        .background(Color.appBackground)
        .sheet(item: $selectedPost) { post in
            FeedPostSheet(
                post: post,
                currentUserId: currentUser.userId,
                connectedUserIds: []
            )
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
        .sheet(isPresented: $showComposer) {
            PostComposerView(viewModel: FeedViewModel())
        }
        .sheet(isPresented: $showPreferences) {
            NotificationPreferencesView()
                .environmentObject(currentUser)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .task {
            if let userId = currentUser.userId {
                viewModel.subscribe(userId: userId)
            }
            AnalyticsService.shared.track(.notificationsViewed)
        }
        .errorAlert($viewModel.actionError)
    }

    // MARK: - Header

    /// Mirrors BrandTopNav (avatar + title) with a trailing preferences action
    /// that opens the notification-category toggles.
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

            Text("Activity")
                .font(.heading1)
                .foregroundColor(.appPrimary)

            Spacer()

            Button { showPreferences = true } label: {
                Image(.navPreferences)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundColor(.appPrimary)
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.pressableScale(0.9))
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.sm)
        .background(Color.appSurface.ignoresSafeArea(edges: .top))
    }

    // MARK: - Notification List

    private var notificationList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                if viewModel.hasUnread {
                    HStack {
                        Spacer()
                        Button(action: {
                            guard let userId = currentUser.userId else { return }
                            Task { await viewModel.markAllAsRead(userId: userId) }
                        }) {
                            Text("Mark all read")
                                .font(.bodyMedium)
                                .foregroundColor(.appSecondary)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                }

                ForEach(viewModel.notifications) { notification in
                    Group {
                        if let eventId = notification.data?.eventId {
                            notificationRow(for: notification)
                                .zoomSource(id: eventId, in: eventZoom)
                        } else {
                            notificationRow(for: notification)
                        }
                    }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            handleTap(notification)
                        }
                        // swipeActions only works inside a List — in this
                        // LazyVStack it rendered nothing, so delete was
                        // unreachable. Long-press is the system alternative.
                        .contextMenu {
                            Button(role: .destructive) {
                                Task { await viewModel.remove(notification) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }

                    if notification.id != viewModel.notifications.last?.id {
                        Rectangle()
                            .fill(Color.appDivider)
                            .frame(height: hairline)
                    }
                }

                Color.clear.frame(height: 80)
            }
        }
        .scrollEdgeFade(top: true, bottom: false)
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

    // MARK: - Row Builder

    @ViewBuilder
    private func notificationRow(for notification: NotificationResponse) -> some View {
        let zoomID = notification.sender.map { AnyHashable($0._id) }
        if notification.type == "connection_request" {
            if notification.isRead {
                NotificationRow(
                    notification: notification,
                    profileZoomID: zoomID,
                    profileZoomNamespace: profileZoom
                )
            } else {
                NotificationRow(
                    notification: notification,
                    onAccept: {
                        Task { await viewModel.acceptConnection(notification) }
                    },
                    onReject: {
                        Task { await viewModel.rejectConnection(notification) }
                    },
                    profileZoomID: zoomID,
                    profileZoomNamespace: profileZoom
                )
            }
        } else {
            NotificationRow(
                notification: notification,
                profileZoomID: zoomID,
                profileZoomNamespace: profileZoom
            )
        }
    }

    // MARK: - Tap Handler

    private func handleTap(_ notification: NotificationResponse) {
        Task { await viewModel.markAsRead(notification) }

        AnalyticsService.shared.track(.notificationTapped(type: notification.type))

        switch notification.type {
        case "comment", "mention":
            if let postId = notification.data?.postId {
                Task {
                    if let post = try? await ConvexClientManager.shared.fetchPost(postId: postId) {
                        selectedPost = post
                    }
                }
            }
        case "connection_request", "connection_accepted", "pending_connection_reminder":
            if let senderId = notification.data?.senderId {
                Task {
                    if let user = try? await ConvexClientManager.shared.fetchUser(id: senderId) {
                        selectedUserProfile = user
                    }
                }
            }
        case "event_rsvp", "event_reminder", "new_event":
            if let eventId = notification.data?.eventId {
                Task {
                    if let event = try? await ConvexClientManager.shared.fetchEvent(id: eventId, userId: currentUser.userId) {
                        selectedEvent = event
                    }
                }
            }
        case "new_message", "message_request":
            if let senderId = notification.data?.senderId {
                Task {
                    if let user = try? await ConvexClientManager.shared.fetchUser(id: senderId) {
                        chatConversationId = notification.data?.conversationId
                        chatParticipant = user
                    }
                }
            }
        case "content_prompt":
            showComposer = true
        case "meet_nudge":
            if let conversationId = notification.data?.conversationId {
                if let senderId = notification.data?.senderId {
                    Task {
                        if let user = try? await ConvexClientManager.shared.fetchUser(id: senderId) {
                            chatConversationId = conversationId
                            chatParticipant = user
                        }
                    }
                }
            }
        case "weekly_digest", "inactivity_nudge", "milestone":
            break
        default:
            break
        }
    }
}

#Preview {
    NotificationsView()
        .environmentObject(CurrentUserManager.shared)
}
