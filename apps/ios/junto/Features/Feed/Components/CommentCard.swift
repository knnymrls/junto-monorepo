//
//  CommentCard.swift
//  mkrs-world
//
//  Comment row with avatar, connection badge, content, and actions
//

import SwiftUI

struct CommentCard: View {
    let comment: CommentResponse
    let connectionStatus: ConnectionDisplayStatus
    let currentUserId: String?
    var onConnectTap: (() -> Void)? = nil
    var onDisconnectTap: (() -> Void)? = nil
    var onEditTap: (() -> Void)? = nil
    var onDeleteTap: (() -> Void)? = nil
    var onReportTap: (() -> Void)? = nil
    var onMentionTap: ((String) -> Void)? = nil
    var onAuthorTap: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            // Avatar with connection badge
            AvatarAction(
                avatarUrl: comment.author?.avatarUrl,
                name: comment.author?.name ?? "?",
                size: 40,
                connectionStatus: connectionStatus,
                isOwnPost: currentUserId == comment.authorId,
                onAvatarTap: { onAuthorTap?() },
                onConnectTap: { onConnectTap?() },
                onDisconnectTap: { onDisconnectTap?() }
            )

            // Content
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                // Header
                HStack {
                    HStack(spacing: Spacing.xxs) {
                        Text(comment.author?.name ?? "Unknown")
                            .font(.bodyMedium)
                            .foregroundColor(.appPrimary)

                        Text(comment.createdDate.timeAgoShort())
                            .font(.body14)
                            .foregroundColor(.appSecondary)
                    }

                    Spacer()

                    Menu {
                        if currentUserId == comment.authorId {
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
                            .foregroundColor(.appSecondary)
                            .padding(Spacing.lg)
                            .contentShape(Rectangle())
                            .padding(-Spacing.sm)
                    }
                }

                // Content with tappable mentions
                MentionText(
                    content: comment.content,
                    onMentionTap: onMentionTap
                )

                // Comment image
                if let imageUrl = comment.imageUrl, let url = URL(string: imageUrl) {
                    CachedAsyncImage(url: url) { image in
                        ExpandableImage(url: url, cornerRadius: Radius.md) {
                            image.resizable().aspectRatio(contentMode: .fit)
                        }
                        .frame(maxHeight: 180)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: Radius.md)
                            .fill(Color.appSurfaceSecondary)
                            .frame(height: 100)
                            .overlay(
                                ProgressView()
                                    .tint(.appSecondary)
                            )
                    }
                    .padding(.top, Spacing.sm)
                }

                // Comment GIF
                if let gifUrlString = comment.gifUrl, let gifUrl = URL(string: gifUrlString) {
                    GifPlayerView(url: gifUrl)
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                        .padding(.top, Spacing.sm)
                }

                // Comment link
                if let linkUrlString = comment.linkUrl, let url = URL(string: linkUrlString) {
                    CompactLinkPreviewCard(url: url)
                        .padding(.top, Spacing.sm)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .background(Color.appSurface)
    }
}
