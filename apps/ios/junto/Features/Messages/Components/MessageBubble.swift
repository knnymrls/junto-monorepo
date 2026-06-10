//
//  MessageBubble.swift
//  mkrs-world
//
//  Sent/received message bubble with read receipts, reactions, reply quote,
//  and edit/delete states. Long-press opens the actions menu.
//

import SwiftUI

/// Quick reactions offered in the long-press menu and rendered as pills.
let messageReactionEmojis = ["❤️", "👍", "😂", "😮", "😢", "🙏"]

struct MessageBubble: View {
    let message: MessageResponse
    let isSent: Bool
    var currentUserId: String = ""
    /// The message this one is replying to (already resolved), plus who wrote it.
    var replyAuthor: String? = nil
    var replyText: String? = nil

    var onReply: () -> Void = {}
    var onEdit: () -> Void = {}
    var onDelete: () -> Void = {}
    var onReact: (String) -> Void = { _ in }

    var body: some View {
        HStack {
            if isSent { Spacer(minLength: 60) }

            VStack(alignment: isSent ? .trailing : .leading, spacing: Spacing.xxxs) {
                if replyAuthor != nil { replyQuote }

                bubbleContent

                if !message.groupedReactions.isEmpty {
                    reactionsRow
                }

                metaRow
            }

            if !isSent { Spacer(minLength: 60) }
        }
        .padding(.vertical, 1)
    }

    // MARK: - Bubble content

    @ViewBuilder
    private var bubbleContent: some View {
        if message.isDeleted {
            Text("Message deleted")
                .font(.bodyLarge)
                .italic()
                .foregroundColor(.appSecondary)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.appDivider, lineWidth: 1)
                )
        } else if let gifUrlString = message.gifUrl, let gifUrl = URL(string: gifUrlString) {
            GifPlayerView(url: gifUrl)
                .frame(maxWidth: 240, maxHeight: 200)
                .clipShape(RoundedRectangle(cornerRadius: Radius.xxl))
                .contextMenu { menuItems }
        } else {
            Text(message.content)
                .font(.bodyLarge)
                .foregroundColor(isSent ? .white : .appPrimary)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
                .background(isSent ? Color.appPrimary : Color.appSurfaceSecondary, in: RoundedRectangle(cornerRadius: 18))
                .contextMenu { menuItems }
        }
    }

    // MARK: - Reply quote

    private var replyQuote: some View {
        HStack(spacing: Spacing.xs) {
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.appSecondary.opacity(0.5))
                .frame(width: 2)

            VStack(alignment: .leading, spacing: 1) {
                Text(replyAuthor ?? "")
                    .font(.captionSmallSemibold)
                    .foregroundColor(.appSecondary)
                Text(replyText ?? "")
                    .font(.caption12)
                    .foregroundColor(.appSecondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: 220, alignment: .leading)
        .padding(.horizontal, Spacing.xs)
        .padding(.bottom, 1)
    }

    // MARK: - Reactions

    private var reactionsRow: some View {
        HStack(spacing: Spacing.xxs) {
            ForEach(message.groupedReactions, id: \.emoji) { group in
                let reactedByMe = group.userIds.contains(currentUserId)
                Button { onReact(group.emoji) } label: {
                    HStack(spacing: 2) {
                        Text(group.emoji).font(.system(size: 12))
                        if group.userIds.count > 1 {
                            Text("\(group.userIds.count)")
                                .font(.captionSmallSemibold)
                                .foregroundColor(reactedByMe ? .appOnAccent : .appSecondary)
                        }
                    }
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, 2)
                    .background(reactedByMe ? Color.appPrimary : Color.appSurfaceSecondary, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 1)
    }

    // MARK: - Meta (time · edited · read receipt)

    private var metaRow: some View {
        HStack(spacing: Spacing.xxxs) {
            if message.isEdited && !message.isDeleted {
                Text("edited")
                    .font(.micro)
                    .foregroundColor(.appSecondary)
                Text("·")
                    .font(.micro)
                    .foregroundColor(.appSecondary)
            }

            Text(timeString(from: message.createdDate))
                .font(.micro)
                .foregroundColor(.appSecondary)

            if isSent && !message.isDeleted {
                readReceipt
            }
        }
    }

    // MARK: - Context menu

    @ViewBuilder
    private var menuItems: some View {
        if !message.isDeleted {
            Menu {
                ForEach(messageReactionEmojis, id: \.self) { emoji in
                    Button(emoji) { onReact(emoji) }
                }
            } label: {
                Label("React", systemImage: "face.smiling")
            }

            Button { onReply() } label: {
                Label("Reply", systemImage: "arrowshape.turn.up.left")
            }

            if message.gifUrl == nil {
                Button {
                    UIPasteboard.general.string = message.content
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
            }

            if isSent && message.gifUrl == nil {
                Button { onEdit() } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }

            if isSent {
                Button(role: .destructive) { onDelete() } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    @ViewBuilder
    private var readReceipt: some View {
        if message.isRead {
            HStack(spacing: -4) {
                Image(systemName: "checkmark")
                    .font(.microBold)
                Image(systemName: "checkmark")
                    .font(.microBold)
            }
            .foregroundColor(.appSecondary)
        } else {
            Image(systemName: "checkmark")
                .font(.microBold)
                .foregroundColor(.appSecondary)
        }
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}
