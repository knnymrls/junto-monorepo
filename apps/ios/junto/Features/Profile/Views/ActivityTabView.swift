//
//  ActivityTabView.swift
//  junto
//
//  Activity tab — the maker's posts as bordered cards (category pill + time +
//  content) and the events they've shown up to. Connection count lives in the
//  hero stat line, not here.
//

import SwiftUI
import Combine

struct ActivityTabView: View {
    let userId: String
    let userName: String
    let isSelf: Bool
    let connectionCount: Int
    @State private var posts: [PostResponse] = []
    @State private var events: [AttendedEventResponse] = []
    @State private var isLoadingPosts = true
    @State private var isLoadingEvents = true
    @State private var postsCancellable: AnyCancellable?
    @State private var eventsCancellable: AnyCancellable?

    private var isFullyLoaded: Bool {
        !isLoadingPosts && !isLoadingEvents
    }

    private var hasNoActivity: Bool {
        isFullyLoaded && posts.isEmpty && events.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxl) {
            if !isFullyLoaded {
                ProgressView()
                    .tint(.appSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.huge)
            } else if hasNoActivity {
                emptyState
            } else {
                if !posts.isEmpty {
                    postsSection
                }

                if !events.isEmpty {
                    eventsSection
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.xxxl)
        .onAppear {
            startPostsSubscription()
            startEventsSubscription()
        }
        .onDisappear {
            postsCancellable?.cancel()
            eventsCancellable?.cancel()
        }
    }

    // MARK: - Posts

    private var postsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionHeader("Posts")

            LazyVStack(spacing: Spacing.md) {
                ForEach(posts) { post in
                    postCard(post)
                }
            }
        }
    }

    private func postCard(_ post: PostResponse) -> some View {
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
    }

    // MARK: - Events

    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionHeader("Events")

            LazyVStack(spacing: Spacing.lg) {
                ForEach(events) { event in
                    eventRow(event)
                }
            }
        }
    }

    private func eventRow(_ event: AttendedEventResponse) -> some View {
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
                    Text(event.eventDate.formatted(date: .abbreviated, time: .omitted))
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
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.captionSmallSemibold)
            .foregroundColor(.appSecondary)
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
