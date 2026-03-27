//
//  ConversationRow.swift
//  mkrs-world
//
//  Avatar + name + last message + timestamp row
//

import SwiftUI

struct ConversationRow: View {
    let conversation: ConversationResponse
    let currentUserId: String?

    var body: some View {
        HStack(spacing: Spacing.sm) {
            AvatarView(
                avatarUrl: conversation.otherParticipant?.avatarUrl,
                name: conversation.otherParticipant?.name ?? "?",
                size: 56
            )

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(conversation.otherParticipant?.name ?? "Unknown")
                    .font(hasUnread ? .bodySemibold : .bodyMedium)
                    .foregroundColor(.appPrimary)
                    .lineLimit(1)

                HStack(spacing: Spacing.xxs) {
                    if let preview = conversation.lastMessagePreview {
                        Text(preview)
                            .font(hasUnread ? .bodyMedium : .body14)
                            .foregroundColor(hasUnread ? .appPrimary : .appSecondary)
                            .lineLimit(1)
                    }

                    Text("· \(conversation.lastMessageDate.timeAgoShort())")
                        .font(.body14)
                        .foregroundColor(.appSecondary)
                        .layoutPriority(1)
                }
            }

            Spacer(minLength: 0)

            if conversation.isSentRequest == true {
                Text("Requested")
                    .font(.bodySmallMedium)
                    .foregroundColor(.appSecondary)
            } else if hasUnread {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    private var hasUnread: Bool {
        (conversation.unreadCount ?? 0) > 0
    }
}
