//
//  NotificationRow.swift
//  mkrs-world
//
//  Individual notification row with avatar, content, actions, and unread indicator
//

import SwiftUI

struct NotificationRow: View {
    let notification: NotificationResponse
    var titleOverride: String? = nil
    var onAccept: (() -> Void)? = nil
    var onReject: (() -> Void)? = nil
    var actionStatus: String? = nil

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            // Avatar
            AvatarView(
                avatarUrl: notification.sender?.avatarUrl,
                name: notification.sender?.name ?? "?",
                size: 40
            )

            // Content
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(titleOverride ?? notification.title)
                    .font(notification.isRead ? .body14 : .bodyMedium)
                    .foregroundColor(.appPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let body = notification.body, !body.isEmpty {
                    Text(body)
                        .font(.bodySmall)
                        .foregroundColor(.appSecondary)
                        .lineLimit(1)
                }

                Text(notification.createdDate.timeAgoShort())
                    .font(.caption12)
                    .foregroundColor(.appSecondary)

                // Accept/Reject buttons for connection requests
                if let onAccept = onAccept, let onReject = onReject {
                    HStack(spacing: Spacing.sm) {
                        Button(action: onAccept) {
                            Text("Accept")
                                .font(.bodySmallSemibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, Spacing.lg)
                                .padding(.vertical, Spacing.xs)
                                .background(Color.appPrimary)
                                .cornerRadius(Radius.xxl)
                        }

                        Button(action: onReject) {
                            Text("Decline")
                                .font(.bodySmallMedium)
                                .foregroundColor(.appSecondary)
                                .padding(.horizontal, Spacing.lg)
                                .padding(.vertical, Spacing.xs)
                                .background(Color.appSurfaceSecondary)
                                .cornerRadius(Radius.xxl)
                        }
                    }
                    .padding(.top, Spacing.xxs)
                } else if let status = actionStatus {
                    Text(status)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.appSecondary)
                        .padding(.top, Spacing.xxs)
                }
            }

            Spacer(minLength: 0)

            // Unread indicator
            if !notification.isRead && onAccept == nil {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
                    .padding(.top, Spacing.xs)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .background(notification.isRead ? Color.appSurface : Color.appSurfaceSecondary.opacity(0.5))
    }
}
