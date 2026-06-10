//
//  FeedCard.swift
//  junto
//
//  Unified feed card for the redesigned feed. One layout, three kinds:
//  post → Ask, event → Opportunity, match → Match (see FeedTypeLabel).
//  Currently renders the designed kinds — post (Figma 70:1623) and
//  match (Figma 70:1711). Events fall through to EmptyView until their
//  card is designed.
//
//  Reuses: AvatarAction (avatar + connect badge), FeedTypeLabel,
//  MentionText, TopicTag + FlowLayout.
//

import SwiftUI

struct FeedCard: View {
    let item: FeedItemResponse
    let connectionStatus: ConnectionDisplayStatus
    let isOwnItem: Bool
    var onConnectTap: (() -> Void)? = nil
    var onDisconnectTap: (() -> Void)? = nil
    var onCardTap: (() -> Void)? = nil
    var onAuthorTap: (() -> Void)? = nil
    var onMentionTap: ((String) -> Void)? = nil
    /// When set, the author avatar acts as the source of a zoom transition
    /// into that user's profile (paired with `.zoomDestination` on ProfileView).
    var profileZoomID: AnyHashable? = nil
    var profileZoomNamespace: Namespace.ID? = nil

    var body: some View {
        if let data = display {
            HStack(alignment: .top, spacing: Spacing.md) {
                AvatarAction(
                    avatarUrl: data.avatarUrl,
                    name: data.name,
                    size: 44,
                    connectionStatus: connectionStatus,
                    isOwnPost: isOwnItem,
                    onAvatarTap: { onAuthorTap?() },
                    onConnectTap: { onConnectTap?() },
                    onDisconnectTap: { onDisconnectTap?() },
                    zoomID: profileZoomID,
                    zoomNamespace: profileZoomNamespace
                )
                .frame(width: 44, height: 48)

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        header(data)
                        bodyText(data)
                    }

                    if !item.displayTags.isEmpty {
                        FlowLayout(spacing: Spacing.md) {
                            ForEach(item.displayTags, id: \.self) { tag in
                                TopicTag(category: tag)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.lg)
            .background(Color.appSurface)
            .contentShape(Rectangle())
            .onTapGesture { onCardTap?() }
        }
    }

    // MARK: - Header (name + time · type label)

    private func header(_ data: Display) -> some View {
        HStack(alignment: .center) {
            HStack(alignment: .center, spacing: Spacing.sm) {
                Text(data.name)
                    .font(.caption12)
                    .foregroundColor(.appPrimary)

                if let timeAgo = data.timeAgo {
                    Text(timeAgo)
                        .font(.caption12)
                        .foregroundColor(.appSecondary)
                }
            }

            Spacer(minLength: Spacing.sm)

            FeedTypeLabel(kind: data.labelKind)
        }
    }

    // MARK: - Body (16pt medium)

    @ViewBuilder
    private func bodyText(_ data: Display) -> some View {
        if data.useMentions {
            MentionText(
                content: data.text,
                onMentionTap: onMentionTap,
                font: .bodyLargeMedium,
                mentionFont: .bodyLargeMedium
            )
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text(data.text)
                .font(.bodyLargeMedium)
                .foregroundColor(.appPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Per-kind display data

    private struct Display {
        let avatarUrl: String?
        let name: String
        let timeAgo: String?
        let labelKind: FeedTypeLabel.Kind
        let text: String
        let useMentions: Bool
    }

    /// Maps the feed item's kind to the fields the card renders. Returns nil
    /// for kinds without a designed card yet (events) so they render nothing.
    private var display: Display? {
        switch item.content {
        case .post(let post):
            return Display(
                avatarUrl: post.author?.avatarUrl,
                name: post.author?.name ?? "Unknown",
                timeAgo: post.createdDate.timeAgoShort(),
                labelKind: .ask,
                text: post.content,
                useMentions: true
            )
        case .match(let match):
            return Display(
                avatarUrl: match.avatarUrl,
                name: match.name,
                timeAgo: nil,
                labelKind: .match,
                text: match.matchReason,
                useMentions: false
            )
        case .event, .digest, .vouch, .momentum, .milestone, .prompt, .caughtUp, .none:
            // Not person/post cards — rendered by their own views in FeedView.
            return nil
        }
    }
}

// MARK: - Preview

#Preview {
    let askItem = FeedItemResponse(
        kind: "post",
        key: "preview_post",
        tags: ["Software Development", "Design"],
        post: PostResponse(
            _id: "preview_post",
            authorId: "mock_1",
            content: "Need someone to help out with development and coding a new suite of features.",
            category: "asking",
            topics: ["Software Development", "Design"],
            imageUrl: nil,
            imageUrls: nil,
            linkUrl: nil,
            gifUrl: nil,
            createdAt: Date().addingTimeInterval(-7200).timeIntervalSince1970 * 1000,
            updatedAt: Date().addingTimeInterval(-7200).timeIntervalSince1970 * 1000,
            author: UserResponse.mock,
            commentCount: 0,
            recentCommenters: nil
        ),
        event: nil,
        match: nil
    )

    let matchItem = FeedItemResponse(
        kind: "match",
        key: "preview_match",
        tags: ["Software Development", "Design"],
        post: nil,
        event: nil,
        match: .mock
    )

    return ScrollView {
        VStack(spacing: 0) {
            FeedCard(item: askItem, connectionStatus: .none, isOwnItem: false)
            Divider()
            FeedCard(item: matchItem, connectionStatus: .none, isOwnItem: false)
        }
    }
    .background(Color.appBackground)
}
