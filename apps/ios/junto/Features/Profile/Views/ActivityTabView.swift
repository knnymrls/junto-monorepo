//
//  ActivityTabView.swift
//  mkrs-world
//
//  Activity tab — posts, events attended, connection stats
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
        isFullyLoaded && posts.isEmpty && events.isEmpty && connectionCount == 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            if !isFullyLoaded {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.huge)
            } else if hasNoActivity {
                emptyState
            } else {
                // Posts (most relevant, show first)
                if !posts.isEmpty {
                    postsSection
                }

                // Events Attended
                if !events.isEmpty {
                    eventsSection
                }

                // Connection Stats
                if connectionCount > 0 {
                    statsSection
                }
            }
        }
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

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader("Connections")

            HStack(spacing: Spacing.md) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.appAccent)

                Text("\(connectionCount) connection\(connectionCount == 1 ? "" : "s")")
                    .font(.body14)
                    .foregroundColor(.appPrimary)
            }
            .padding(.horizontal, Spacing.lg)
        }
    }

    // MARK: - Events Section

    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader("Events Attended")

            LazyVStack(spacing: 0) {
                ForEach(events) { event in
                    eventRow(event)
                }
            }
        }
    }

    private func eventRow(_ event: AttendedEventResponse) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "calendar")
                .font(.system(size: 14))
                .foregroundColor(.appSecondary)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(event.title)
                    .font(.bodySemibold)
                    .foregroundColor(.appPrimary)
                    .lineLimit(1)

                HStack(spacing: Spacing.xs) {
                    Text(event.eventDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption12)
                        .foregroundColor(.appSecondary)

                    if let location = event.location {
                        Text("·")
                            .foregroundColor(.appSecondary)
                        Text(location)
                            .font(.caption12)
                            .foregroundColor(.appSecondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
    }

    // MARK: - Posts Section

    private var postsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader("Posts")

            LazyVStack(spacing: 0) {
                ForEach(posts) { post in
                    postRow(post)
                    Divider()
                        .foregroundColor(.appDivider)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "clock")
                .font(.system(size: 32))
                .foregroundColor(.appSecondary)

            Text("No activity yet")
                .font(.bodyLargeMedium)
                .foregroundColor(.appSecondary)

            Text("Posts, events, and connections will show up here.")
                .font(.body14)
                .foregroundColor(.appSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.huge)
    }

    private func postRow(_ post: PostResponse) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Text(post.categoryType.displayName)
                    .font(.captionSemibold)
                    .foregroundColor(.appSecondary)

                Text("·")
                    .foregroundColor(.appSecondary)

                Text(post.createdDate.timeAgoDisplay())
                    .font(.caption12)
                    .foregroundColor(.appSecondary)
            }

            Text(post.content)
                .font(.body14)
                .foregroundColor(.appPrimary)
                .lineLimit(4)

            if !post.allImageUrls.isEmpty {
                ImageCarousel(imageUrls: post.allImageUrls)
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            }

            if let commentCount = post.commentCount, commentCount > 0 {
                Text("\(commentCount) comment\(commentCount == 1 ? "" : "s")")
                    .font(.caption12)
                    .foregroundColor(.appSecondary)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.bodySmallSemibold)
            .foregroundColor(.appSecondary)
            .padding(.horizontal, Spacing.lg)
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
