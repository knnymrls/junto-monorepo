//
//  PostsTabView.swift
//  mkrs-world
//
//  Posts tab — shows user's posts in simplified cards
//

import SwiftUI
import Combine

struct PostsTabView: View {
    let authorId: String
    let authorName: String
    let isSelf: Bool
    @State private var posts: [PostResponse] = []
    @State private var isLoading = true
    @State private var cancellable: AnyCancellable?

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView()
                    .padding(.top, 40)
            } else if posts.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(posts) { post in
                        postRow(post)
                        Divider()
                            .foregroundColor(.appDivider)
                    }
                }
            }
        }
        .onAppear { startSubscription() }
        .onDisappear { cancellable?.cancel() }
    }

    // MARK: - Post Row

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

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "text.bubble")
                .font(.system(size: 32))
                .foregroundColor(.appSecondary)

            Text("No posts yet")
                .font(.bodyLargeMedium)
                .foregroundColor(.appSecondary)

            if isSelf {
                Text("Share what you're working on!")
                    .font(.body14)
                    .foregroundColor(.appSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.huge)
    }

    // MARK: - Subscription

    private func startSubscription() {
        cancellable = ConvexClientManager.shared.subscribePostsByAuthor(authorId: authorId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("PostsTabView: subscription error: \(error)")
                    }
                },
                receiveValue: { newPosts in
                    posts = newPosts
                    isLoading = false
                }
            )
    }
}
