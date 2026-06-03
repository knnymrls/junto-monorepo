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
    /// When set, the comment author avatar acts as a zoom-transition source
    /// into that user's profile.
    var profileZoomID: AnyHashable? = nil
    var profileZoomNamespace: Namespace.ID? = nil

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            // Avatar with connection badge
            AvatarAction(
                avatarUrl: comment.author?.avatarUrl,
                name: comment.author?.name ?? "?",
                size: 44,
                connectionStatus: connectionStatus,
                isOwnPost: currentUserId == comment.authorId,
                onAvatarTap: { onAuthorTap?() },
                onConnectTap: { onConnectTap?() },
                onDisconnectTap: { onDisconnectTap?() },
                zoomID: profileZoomID,
                zoomNamespace: profileZoomNamespace
            )

            // Content
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                // Header
                HStack(spacing: Spacing.sm) {
                    Text(comment.author?.name ?? "Unknown")
                        .font(.caption12)
                        .foregroundColor(.appPrimary)

                    Text(comment.createdDate.timeAgoShort())
                        .font(.caption12)
                        .foregroundColor(.appSecondary)
                }

                // Content with tappable mentions — body is 14pt medium (Figma 101:2055)
                MentionText(
                    content: comment.content,
                    onMentionTap: onMentionTap,
                    font: .bodyMedium
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
        // Fill the row width and left-align — otherwise a short comment shrinks
        // the HStack to its content and the parent VStack centers it (looks
        // like a random right-indent on short replies).
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.lg)
        .background(Color.appSurface)
    }
}
