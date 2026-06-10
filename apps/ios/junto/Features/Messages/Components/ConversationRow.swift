//
//  ConversationRow.swift
//  mkrs-world
//
//  Conversation row, styled to match the unified Feed / Discover card:
//  avatar + small name label + prominent last-message line, with a top-right
//  status label (Request / Requested) or unread dot. Padded md/lg on surface.
//

import SwiftUI

struct ConversationRow: View {
    let conversation: ConversationResponse
    let currentUserId: String?

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            AvatarView(
                avatarUrl: conversation.otherParticipant?.avatarUrl,
                name: conversation.otherParticipant?.name ?? "?",
                size: 44
            )
            .frame(width: 44, height: 48)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                header
                preview
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.lg)
        .background(Color.appSurface)
        .contentShape(Rectangle())
    }

    // MARK: - Header (name + time · status)

    private var header: some View {
        HStack(alignment: .center) {
            HStack(alignment: .center, spacing: Spacing.sm) {
                Text(conversation.otherParticipant?.name ?? "Unknown")
                    .font(.caption12)
                    .foregroundColor(.appPrimary)
                    .lineLimit(1)

                Text(conversation.lastMessageDate.timeAgoShort())
                    .font(.caption12)
                    .foregroundColor(.appSecondary)
                    .layoutPriority(1)
            }

            Spacer(minLength: Spacing.sm)

            trailingStatus
        }
    }

    // MARK: - Body (last message preview, 16pt medium like the feed body)

    private var preview: some View {
        Text(previewText)
            .font(hasUnread ? .bodyLargeMedium : .bodyLarge)
            .foregroundColor(.appPrimary)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Trailing status

    @ViewBuilder
    private var trailingStatus: some View {
        if conversation.isRequest == true {
            MessageStatusLabel(kind: .request)
        } else if conversation.isSentRequest == true {
            MessageStatusLabel(kind: .requested)
        } else if hasUnread {
            Circle()
                .fill(Color.blue)
                .frame(width: 8, height: 8)
        }
    }

    // MARK: - Derived

    private var previewText: String {
        if let preview = conversation.lastMessagePreview, !preview.isEmpty {
            return preview
        }
        return "Say hi to start the conversation"
    }

    private var hasUnread: Bool {
        (conversation.unreadCount ?? 0) > 0
    }
}
