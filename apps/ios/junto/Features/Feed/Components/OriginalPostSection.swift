//
//  OriginalPostSection.swift
//  mkrs-world
//
//  Original post display for the post detail sheet
//

import SwiftUI

struct OriginalPostSection: View {
    let post: PostResponse
    let connectionStatus: ConnectionDisplayStatus
    let currentUserId: String?
    var onAuthorTap: (() -> Void)? = nil
    var onConnectTap: (() -> Void)? = nil
    var onDisconnectTap: (() -> Void)? = nil
    var onEditTap: (() -> Void)? = nil
    var onDeleteTap: (() -> Void)? = nil
    var onMentionTap: ((String) -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            // Left column
            VStack(spacing: Spacing.xxs) {
                AvatarAction(
                    avatarUrl: post.author?.avatarUrl,
                    name: post.author?.name ?? "?",
                    size: 40,
                    connectionStatus: connectionStatus,
                    isOwnPost: currentUserId == post.authorId,
                    onAvatarTap: { onAuthorTap?() },
                    onConnectTap: { onConnectTap?() },
                    onDisconnectTap: { onDisconnectTap?() }
                )
                .frame(width: 40, height: 36)

                Spacer()
            }
            .frame(width: 40)

            // Right column
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    HStack {
                        HStack(spacing: Spacing.xxs) {
                            Text(post.author?.name ?? "Unknown")
                                .font(.bodyMedium)
                                .foregroundColor(.appPrimary)

                            Text(post.createdDate.timeAgoShort())
                                .font(.body14)
                                .foregroundColor(.appSecondary)
                        }

                        Spacer()

                        Menu {
                            if currentUserId == post.authorId {
                                Button(action: { onEditTap?() }) {
                                    Label("Edit", systemImage: "pencil")
                                }
                                Button(role: .destructive, action: { onDeleteTap?() }) {
                                    Label("Delete", systemImage: "trash")
                                }
                            } else {
                                Button(action: {}) {
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

                    MentionText(
                        content: post.content,
                        onMentionTap: onMentionTap
                    )
                }

                if !post.allImageUrls.isEmpty {
                    postImageSection
                }

                if let gifUrlString = post.gifUrl, let gifUrl = URL(string: gifUrlString) {
                    GifPlayerView(url: gifUrl)
                        .frame(maxHeight: 240)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                }

                if let linkUrlString = post.linkUrl, let url = URL(string: linkUrlString) {
                    LinkPreviewCard(url: url)
                }

                HStack {
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

                    Spacer()

                    CategoryPill(category: post.categoryType)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.lg)
        .background(Color.appSurface)
    }

    // MARK: - Post Image Section

    private var postImageSection: some View {
        let leftBleed: CGFloat = 40 + Spacing.sm
        let allUrls = post.allImageUrls.compactMap { URL(string: $0) }
        return ScrollView(.horizontal, showsIndicators: false) {
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
                    }
                }
            }
            .padding(.leading, leftBleed + Spacing.md)
            .padding(.trailing, Spacing.md)
        }
        .padding(.leading, -(leftBleed + Spacing.md))
        .padding(.trailing, -Spacing.md)
    }
}
