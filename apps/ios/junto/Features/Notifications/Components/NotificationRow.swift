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
    /// When set, the sender avatar acts as a zoom-transition source into that
    /// user's profile (only used when the notification has a sender).
    var profileZoomID: AnyHashable? = nil
    var profileZoomNamespace: Namespace.ID? = nil

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            avatar

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

    // MARK: - Avatar

    @ViewBuilder
    private var avatar: some View {
        if notification.sender != nil {
            // Sender avatar + a small type badge so the (distinct) type icon
            // still reads on every row.
            AvatarView(
                avatarUrl: notification.sender?.avatarUrl,
                name: notification.sender?.name ?? "?",
                size: 40,
                zoomID: profileZoomID,
                zoomNamespace: profileZoomNamespace
            )
            .overlay(alignment: .bottomTrailing) {
                typeBadge.offset(x: 3, y: 3)
            }
        } else {
            let palette = paletteForType(notification.type)
            Circle()
                .fill(palette.background)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(iconForType(notification.type))
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundColor(palette.foreground)
                )
        }
    }

    /// Small colored type indicator that sits on the corner of the avatar.
    private var typeBadge: some View {
        let palette = paletteForType(notification.type)
        return ZStack {
            Circle()
                .fill(Color.appSurface)
                .frame(width: 20, height: 20)
            Circle()
                .fill(palette.background)
                .frame(width: 17, height: 17)
            Image(iconForType(notification.type))
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 10, height: 10)
                .foregroundColor(palette.foreground)
        }
    }

    /// Streamline Flex SOLID icons — one per notification type so each reads
    /// distinctly (icons on a filled circle are solid).
    private func iconForType(_ type: String) -> ImageResource {
        switch type {
        case "comment": return .notifComments
        case "mention": return .actionMentionFill
        case "connection_request", "connection_accepted", "pending_connection_reminder": return .notifConnections
        case "event_rsvp", "event_reminder", "new_event": return .notifEvents
        case "new_message", "message_request": return .notifMessages
        case "content_prompt": return .notifContent
        case "meet_nudge": return .notifMeet
        case "weekly_digest": return .notifUpdates
        case "inactivity_nudge": return .notifFlame
        case "milestone": return .notifMilestone
        default: return .notifBell
        }
    }

    // MARK: - Type Palette
    // Echoes the CategoryPill colors (sharing=orange, lookingFor=blue,
    // asking=purple) and adds green for the "social" group.

    fileprivate struct TypePalette {
        let background: Color
        let foreground: Color
    }

    fileprivate func paletteForType(_ type: String) -> TypePalette {
        switch type {
        case "comment", "mention", "new_message", "message_request":
            return .blue
        case "connection_request", "connection_accepted", "pending_connection_reminder",
             "inactivity_nudge", "meet_nudge":
            return .green
        case "event_rsvp", "event_reminder", "new_event":
            return .orange
        case "content_prompt", "weekly_digest", "milestone":
            return .purple
        default:
            return .neutral
        }
    }
}

private extension NotificationRow.TypePalette {
    static let blue = NotificationRow.TypePalette(
        background: Color(UIColor { $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.05, green: 0.12, blue: 0.25, alpha: 1.0)
            : UIColor(red: 0.89, green: 0.95, blue: 0.99, alpha: 1.0)  // #E3F2FD
        }),
        foreground: Color(UIColor { $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.35, green: 0.65, blue: 1.00, alpha: 1.0)
            : UIColor(red: 0.08, green: 0.40, blue: 0.75, alpha: 1.0)  // #1565C0
        })
    )

    static let green = NotificationRow.TypePalette(
        background: Color(UIColor { $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.05, green: 0.20, blue: 0.10, alpha: 1.0)
            : UIColor(red: 0.91, green: 0.97, blue: 0.92, alpha: 1.0)  // #E8F5E9
        }),
        foreground: Color(UIColor { $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.40, green: 0.85, blue: 0.50, alpha: 1.0)
            : UIColor(red: 0.18, green: 0.49, blue: 0.20, alpha: 1.0)  // #2E7D32
        })
    )

    static let orange = NotificationRow.TypePalette(
        background: Color(UIColor { $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.25, green: 0.15, blue: 0.05, alpha: 1.0)
            : UIColor(red: 1.00, green: 0.95, blue: 0.88, alpha: 1.0)  // #FFF3E0
        }),
        foreground: Color(UIColor { $0.userInterfaceStyle == .dark
            ? UIColor(red: 1.00, green: 0.55, blue: 0.20, alpha: 1.0)
            : UIColor(red: 0.90, green: 0.32, blue: 0.00, alpha: 1.0)  // #E65100
        })
    )

    static let purple = NotificationRow.TypePalette(
        background: Color(UIColor { $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.18, green: 0.08, blue: 0.25, alpha: 1.0)
            : UIColor(red: 0.95, green: 0.90, blue: 0.96, alpha: 1.0)  // #F3E5F5
        }),
        foreground: Color(UIColor { $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.73, green: 0.40, blue: 0.90, alpha: 1.0)
            : UIColor(red: 0.48, green: 0.12, blue: 0.64, alpha: 1.0)  // #7B1FA2
        })
    )

    static let neutral = NotificationRow.TypePalette(
        background: Color.appSurfaceSecondary,
        foreground: Color.appSecondary
    )
}
