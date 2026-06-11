//
//  ActivityTabView.swift
//  junto
//
//  Activity tab — one recency-ordered timeline mixing the maker's posts and
//  events. Each entry renders as its own kind (post card / event row) and
//  taps through to the real thing (post detail sheet / event detail page).
//

import SwiftUI
import Combine

struct ActivityTabView: View {
    let userId: String
    let userName: String
    let isSelf: Bool
    let connectionCount: Int

    @EnvironmentObject private var currentUser: CurrentUserManager
    @State private var posts: [PostResponse] = []
    @State private var events: [AttendedEventResponse] = []
    @State private var isLoadingPosts = true
    @State private var isLoadingEvents = true
    @State private var selectedPost: PostResponse?
    @State private var selectedEvent: EventWithRsvpResponse?
    @State private var postsCancellable: AnyCancellable?
    @State private var eventsCancellable: AnyCancellable?

    /// Posts and events merged into one timeline, newest first.
    private enum ActivityEntry: Identifiable {
        case post(PostResponse)
        case event(AttendedEventResponse)

        var id: String {
            switch self {
            case .post(let post): return "post-\(post._id)"
            case .event(let event): return "event-\(event._id)"
            }
        }

        var date: Date {
            switch self {
            case .post(let post): return post.createdDate
            case .event(let event): return event.eventDate
            }
        }
    }

    private var timeline: [ActivityEntry] {
        let entries = posts.map(ActivityEntry.post) + events.map(ActivityEntry.event)
        return entries.sorted { $0.date > $1.date }
    }

    private var isFullyLoaded: Bool {
        !isLoadingPosts && !isLoadingEvents
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if !isFullyLoaded {
                ProgressView()
                    .tint(.appSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.huge)
            } else if timeline.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: Spacing.md) {
                    ForEach(timeline) { entry in
                        switch entry {
                        case .post(let post):
                            postCard(post)
                        case .event(let event):
                            eventCard(event)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.xxxl)
        .sheet(item: $selectedPost) { post in
            FeedPostSheet(
                post: post,
                currentUserId: currentUser.userId,
                connectedUserIds: []
            )
        }
        .fullScreenCover(item: $selectedEvent) { event in
            EventDetailView(event: event)
        }
        .onAppear {
            startPostsSubscription()
            startEventsSubscription()
        }
        .onDisappear {
            postsCancellable?.cancel()
            eventsCancellable?.cancel()
        }
    }

    // MARK: - Post Card

    private func postCard(_ post: PostResponse) -> some View {
        Button(action: { selectedPost = post }) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    CategoryPill(category: post.categoryType)

                    Spacer(minLength: 0)

                    Text(post.createdDate.timeAgoShort())
                        .font(.caption12)
                        .foregroundColor(.appSecondary)
                }

                Text(post.content)
                    .font(.body14)
                    .foregroundColor(.appPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                if !post.allImageUrls.isEmpty {
                    ImageCarousel(imageUrls: post.allImageUrls)
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
                }

                if let commentCount = post.commentCount, commentCount > 0 {
                    HStack(spacing: Spacing.xxs) {
                        Image("content.comments")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)

                        Text("\(commentCount) \(commentCount == 1 ? "reply" : "replies")")
                            .font(.caption12)
                    }
                    .foregroundColor(.appSecondary)
                }
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.xxl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.xxl, style: .continuous)
                    .strokeBorder(Color.appBorder, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: Radius.xxl, style: .continuous))
        }
        .buttonStyle(.pressableScale(0.98))
    }

    // MARK: - Event Card

    private func eventCard(_ event: AttendedEventResponse) -> some View {
        Button(action: { openEvent(event) }) {
            HStack(spacing: Spacing.md) {
                Image("feed.calendar")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundColor(.appPrimary)
                    .frame(width: 36, height: 36)
                    .background(Color.appSurfaceSecondary)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    Text(event.title)
                        .font(.bodySemibold)
                        .foregroundColor(.appPrimary)
                        .lineLimit(1)

                    HStack(spacing: Spacing.xs) {
                        Text(eventDateText(event))
                            .font(.caption12)
                            .foregroundColor(.appSecondary)

                        if let location = event.location, !location.isEmpty {
                            Text("·")
                                .font(.caption12)
                                .foregroundColor(.appSecondary)
                            Text(location)
                                .font(.caption12)
                                .foregroundColor(.appSecondary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.appSecondary)
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.xxl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.xxl, style: .continuous)
                    .strokeBorder(Color.appBorder, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: Radius.xxl, style: .continuous))
        }
        .buttonStyle(.pressableScale(0.98))
    }

    private func eventDateText(_ event: AttendedEventResponse) -> String {
        event.eventDate.formatted(date: .abbreviated, time: .omitted)
    }

    private func openEvent(_ event: AttendedEventResponse) {
        Task {
            if let full = try? await ConvexClientManager.shared.fetchEvent(id: event._id) {
                await MainActor.run { selectedEvent = full }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            icon: "clock",
            title: "No activity yet",
            subtitle: isSelf
                ? "Your posts and events will show up here."
                : "\(userName.components(separatedBy: " ").first ?? userName)'s posts and events will show up here.",
            iconSize: 32
        )
    }

    // MARK: - Subscriptions

    private func startPostsSubscription() {
        postsCancellable = ConvexClientManager.shared.subscribePostsByAuthor(authorId: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("ActivityTabView: posts subscription error: \(error)")
                        isLoadingPosts = false
                    }
                },
                receiveValue: { newPosts in
                    posts = newPosts
                    isLoadingPosts = false
                }
            )
    }

    private func startEventsSubscription() {
        eventsCancellable = ConvexClientManager.shared.subscribeEventsAttended(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("ActivityTabView: events subscription error: \(error)")
                        isLoadingEvents = false
                    }
                },
                receiveValue: { newEvents in
                    events = newEvents
                    isLoadingEvents = false
                }
            )
    }
}
