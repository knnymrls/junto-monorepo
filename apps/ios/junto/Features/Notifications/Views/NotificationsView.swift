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

    var body: some View {
        VStack(spacing: 0) {
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
        .sheet(item: $selectedUserProfile) { user in
            ProfileView(user: user)
        }
        .sheet(item: $selectedEvent) { event in
            EventDetailView(event: event)
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
        .task {
            if let userId = currentUser.userId {
                viewModel.subscribe(userId: userId)
            }
            AnalyticsService.shared.track(.notificationsViewed)
        }
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
                    notificationRow(for: notification)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            handleTap(notification)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task { await viewModel.remove(notification) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }

                Color.clear.frame(height: 80)
            }
        }
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
        if notification.type == "connection_request" {
            if notification.isRead {
                NotificationRow(notification: notification)
            } else {
                NotificationRow(
                    notification: notification,
                    onAccept: {
                        Task { await viewModel.acceptConnection(notification) }
                    },
                    onReject: {
                        Task { await viewModel.rejectConnection(notification) }
                    }
                )
            }
        } else {
            NotificationRow(notification: notification)
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
                    if let event = try? await ConvexClientManager.shared.fetchEvent(id: eventId) {
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
