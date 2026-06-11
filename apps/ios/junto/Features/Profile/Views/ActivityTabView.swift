//
//  ActivityTabView.swift
//  junto
//
//  Activity tab — one recency-ordered timeline of the maker's posts and
//  events, rendered with the app's REAL components: the feed's FeedCard for
//  posts and Discover's DiscoverEventCard for events, separated by the same
//  hairline rows as the feed. Taps open the real post sheet / event detail.
//

import SwiftUI
import Combine

struct ActivityTabView: View {
    let userId: String
    let userName: String
    let isSelf: Bool
    let connectionCount: Int
    /// Viewer ↔ profile connection state, mirrored onto each post card's
    /// avatar badge (same as the feed).
    var connectionStatus: ConnectionDisplayStatus = .none
    var onConnect: () -> Void = {}

    @EnvironmentObject private var currentUser: CurrentUserManager
    @State private var posts: [PostResponse] = []
    @State private var events: [EventResponse] = []
    @State private var isLoadingPosts = true
    @State private var isLoadingEvents = true
    @State private var selectedPost: PostResponse?
    @State private var selectedEvent: EventWithRsvpResponse?
    @State private var postsCancellable: AnyCancellable?
    @State private var eventsCancellable: AnyCancellable?

    private var hairline: CGFloat { 1 / UIScreen.main.scale }

    /// Posts and events merged into one timeline, newest first.
    private enum ActivityEntry: Identifiable {
        case post(PostResponse)
        case event(EventResponse)

        var id: String {
            switch self {
            case .post(let post): return "post-\(post._id)"
            case .event(let event): return "event-\(event._id)"
            }
        }

        var date: Date {
            switch self {
            case .post(let post): return post.createdDate
            case .event(let event): return event.dateValue
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
        LazyVStack(spacing: 0) {
            if !isFullyLoaded {
                ProgressView()
                    .tint(.appSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.huge)
            } else if timeline.isEmpty {
                emptyState
            } else {
                ForEach(timeline) { entry in
                    entryRow(entry)

                    Rectangle()
                        .fill(Color.appDivider)
                        .frame(height: hairline)
                }
            }
        }
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

    // MARK: - Rows (the feed's post card / Discover's event card)

    @ViewBuilder
    private func entryRow(_ entry: ActivityEntry) -> some View {
        switch entry {
        case .post(let post):
            FeedCard(
                item: FeedItemResponse(
                    kind: "post",
                    key: post._id,
                    tags: post.topics,
                    post: post
                ),
                connectionStatus: connectionStatus,
                isOwnItem: post.authorId == currentUser.userId,
                onConnectTap: onConnect,
                onCardTap: { selectedPost = post }
            )

        case .event(let event):
            DiscoverEventCard(
                event: event,
                onCardTap: { openEvent(event) }
            )
        }
    }

    private func openEvent(_ event: EventResponse) {
        Task {
            if let full = try? await ConvexClientManager.shared.fetchEvent(id: event._id) {
                await MainActor.run { selectedEvent = full }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        FeedMessageState(
            icon: "feed.empty",
            title: "No activity yet",
            subtitle: isSelf
                ? "Your posts and events will show up here"
                : "\(userName.components(separatedBy: " ").first ?? userName)'s posts and events will show up here"
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
