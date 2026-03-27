//
//  FeedPostCard.swift
//  mkrs-world
//
//  Individual post card in the feed - matches Figma exactly
//

import SwiftUI

struct FeedPostCard: View {
    let post: PostResponse
    let connectionStatus: ConnectionDisplayStatus
    let isOwnPost: Bool
    var onConnectTap: (() -> Void)? = nil
    var onDisconnectTap: (() -> Void)? = nil
    var onReplyTap: (() -> Void)? = nil
    var onEditTap: (() -> Void)? = nil
    var onDeleteTap: (() -> Void)? = nil
    var onReportTap: (() -> Void)? = nil
    var onAuthorTap: (() -> Void)? = nil
    var onMentionTap: ((String) -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Main content row
            HStack(alignment: .top, spacing: Spacing.md) {
                // Left: avatar + thread line
                VStack(spacing: Spacing.xxs) {
                    AvatarAction(
                        avatarUrl: post.author?.avatarUrl,
                        name: post.author?.name ?? "?",
                        size: 44,
                        connectionStatus: connectionStatus,
                        isOwnPost: isOwnPost,
                        onAvatarTap: { onAuthorTap?() },
                        onConnectTap: { onConnectTap?() },
                        onDisconnectTap: { onDisconnectTap?() }
                    )
                    .frame(width: 44, height: 48)

                    // Thread line — extends into the bottom row gap
                    Capsule()
                        .fill(Color.appDivider)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                        .padding(.bottom, -(Spacing.md + Spacing.xxs))
                }
                .frame(width: 44)

                // Right: header + content + images + link (no footer)
                rightColumn
            }

            // Bottom row — indicator + footer always at same y
            HStack(alignment: .center, spacing: Spacing.md) {
                bottomIndicator
                    .frame(width: 44, height: 30)

                footerRow
                    .frame(height: 30)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, Spacing.md)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.lg)
        .background(Color.appSurface)
    }

    // MARK: - Bottom Indicator

    @ViewBuilder
    private var bottomIndicator: some View {
        let commenters = post.recentCommenters ?? []
        if !commenters.isEmpty {
            // Stacked avatars for replies (max 3)
            HStack(spacing: -12) {
                ForEach(Array(commenters.prefix(3).enumerated()), id: \.element._id) { _, commenter in
                    ZStack {
                        Circle()
                            .fill(Color.appSurface)
                            .frame(width: 24, height: 24)
                        AvatarView(
                            avatarUrl: commenter.avatarUrl,
                            name: commenter.name,
                            size: 20
                        )
                    }
                }
            }
        } else {
            // Chat bubble icon for no replies
            Image("content.comments")
                .renderingMode(.template)
                .resizable()
                .frame(width: 16, height: 16)
                .foregroundColor(.appSecondary)
        }
    }

    // MARK: - Right Column

    private var rightColumn: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header + Content
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                headerRow
                contentText
            }

            // Images (scrollable side-by-side)
            if !post.allImageUrls.isEmpty {
                imageSection
            }

            // GIF
            if let gifUrlString = post.gifUrl, let gifUrl = URL(string: gifUrlString) {
                GifPlayerView(url: gifUrl)
                    .frame(maxHeight: 240)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            }

            // Optional link preview
            if let linkUrlString = post.linkUrl, let url = URL(string: linkUrlString) {
                LinkPreviewCard(url: url)
            }
        }
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack {
            HStack(alignment: .center, spacing: Spacing.sm) {
                Text(post.author?.name ?? "Unknown")
                    .font(.bodySemibold)
                    .foregroundColor(.appPrimary)

                Text(post.createdDate.timeAgoShort())
                    .font(.body14)
                    .foregroundColor(.appSecondary)
            }

            Spacer()

            Menu {
                if isOwnPost {
                    Button(action: { onEditTap?() }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: { onDeleteTap?() }) {
                        Label("Delete", systemImage: "trash")
                    }
                } else {
                    Button(action: { onReportTap?() }) {
                        Label("Report", systemImage: "flag")
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14))
                    .foregroundColor(.appPrimary)
                    .padding(Spacing.lg)
                    .contentShape(Rectangle())
                    .padding(-Spacing.sm)
            }
        }
    }

    // MARK: - Content

    private var contentText: some View {
        MentionText(
            content: post.content,
            onMentionTap: onMentionTap
        )
    }

    // MARK: - Images

    @ObservedObject private var imageViewerManager = ImageViewerManager.shared

    private var imageSection: some View {
        let leftBleed = 44 + Spacing.md
        let allUrls = post.allImageUrls.compactMap { URL(string: $0) }
        return ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(post.allImageUrls, id: \.self) { urlString in
                        if let url = URL(string: urlString) {
                            CachedAsyncImage(url: url) { image in
                                ExpandableImage(url: url, allUrls: allUrls, cornerRadius: Radius.xxxl) {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 240)
                                        .frame(maxWidth: 280)
                                        .clipped()
                                }
                            } placeholder: {
                                RoundedRectangle(cornerRadius: Radius.xxxl)
                                    .fill(Color.appSurfaceSecondary)
                                    .frame(width: 180, height: 240)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: Radius.xxxl))
                            .id(urlString)
                        }
                    }
                }
                .padding(.leading, leftBleed + Spacing.md)
                .padding(.trailing, Spacing.md)
            }
            .onChange(of: imageViewerManager.currentIndex) { _, _ in
                // Scroll feed thumbnails as user pages through expanded viewer
                if let currentUrl = imageViewerManager.selectedImageUrl?.absoluteString,
                   allUrls.contains(where: { $0.absoluteString == currentUrl }) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(currentUrl, anchor: .center)
                    }
                }
            }
        }
        .padding(.leading, -(leftBleed + Spacing.md))
        .padding(.trailing, -Spacing.md)
    }

    // MARK: - Footer Row

    private var footerRow: some View {
        HStack {
            HStack(spacing: Spacing.sm) {
                Button(action: { onReplyTap?() }) {
                    HStack(spacing: Spacing.xxs) {
                        Image("content.reply")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 16, height: 16)
                        Text("Reply...")
                            .font(.body14)
                    }
                    .foregroundColor(.appPrimary)
                }
                .buttonStyle(.plain)

                // TODO: implement share action
                Button(action: {}) {
                    HStack(spacing: Spacing.xxs) {
                        Image("content.share")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 16, height: 16)
                        Text("Share")
                            .font(.body14)
                    }
                    .foregroundColor(.appPrimary)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            CategoryPill(category: post.categoryType)
        }
    }

}

// MARK: - Preview

#Preview {
    ZStack {
        ScrollView {
            VStack(spacing: 0) {
                FeedPostCard(
                    post: .mock,
                    connectionStatus: .none,
                    isOwnPost: true
                )

                Divider()

                FeedPostCard(
                    post: PostResponse(
                        _id: "post_2",
                        authorId: "mock_2",
                        content: "Excited to share that our team is expanding! We're on the lookout for a UX designer.",
                        category: "looking_for",
                        imageUrl: nil,
                        imageUrls: nil,
                        linkUrl: nil,
                        gifUrl: nil,
                        createdAt: Date().addingTimeInterval(-7200).timeIntervalSince1970 * 1000,
                        updatedAt: Date().addingTimeInterval(-7200).timeIntervalSince1970 * 1000,
                        author: UserResponse.mockList[1],
                        commentCount: 3,
                        recentCommenters: [
                            PostResponse.RecentCommenter(_id: "mock_1", name: "Kenny", avatarUrl: nil),
                            PostResponse.RecentCommenter(_id: "mock_3", name: "Marcus", avatarUrl: nil)
                        ]
                    ),
                    connectionStatus: .connected,
                    isOwnPost: false
                )

                Divider()

                FeedPostCard(
                    post: PostResponse(
                        _id: "post_3",
                        authorId: "mock_3",
                        content: "Hi",
                        category: "sharing",
                        imageUrl: nil,
                        imageUrls: nil,
                        linkUrl: nil,
                        gifUrl: nil,
                        createdAt: Date().addingTimeInterval(-3600).timeIntervalSince1970 * 1000,
                        updatedAt: Date().addingTimeInterval(-3600).timeIntervalSince1970 * 1000,
                        author: UserResponse.mockList[2],
                        commentCount: 0,
                        recentCommenters: nil
                    ),
                    connectionStatus: .pending,
                    isOwnPost: false
                )
            }
        }
        .background(Color.appBackground)

        ImageViewerOverlay()
    }
}
