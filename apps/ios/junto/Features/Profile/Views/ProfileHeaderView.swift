//
//  ProfileHeaderView.swift
//  junto
//
//  Profile hero — deliberately minimal: avatar (with the feed's connect
//  badge), a small thought bubble for "looking for", name / headline /
//  campus, an inline stat line, and the action buttons. Everything else
//  (story, tags, skills, programs) lives in the About / Work / Vouches /
//  Activity tabs.
//

import SwiftUI

struct ProfileHeaderView: View {
    let user: UserResponse
    let context: ProfileContextResponse?
    let connectionStatus: ConnectionStatus
    let connectionCount: Int
    let vouchCount: Int
    let postCount: Int
    let hasVouched: Bool
    let isSelf: Bool
    @Binding var isActioning: Bool

    var onEdit: () -> Void = {}
    var onVouch: () -> Void = {}
    var onMessage: () -> Void = {}
    var onConnect: () -> Void = {}
    var onAccept: () -> Void = {}
    var onTapPosts: () -> Void = {}
    var onTapVouches: () -> Void = {}

    private let avatarSize: CGFloat = 72

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            avatarBubbleRow

            nameBlock

            statLine

            actionRow
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.md)
    }

    // MARK: - Avatar + Thought Bubble

    private var avatarBubbleRow: some View {
        HStack(spacing: 0) {
            avatarWithBadge
            Spacer(minLength: 0)
        }
        // The bubble is absolutely placed (overlay, never layout) so its
        // presence or size can't shift the hero.
        .overlay(alignment: .bottomLeading) {
            thoughtBubble
                .padding(.leading, avatarSize + Spacing.lg)
                .offset(y: 6)
        }
    }

    private var avatarWithBadge: some View {
        AvatarView(
            avatarUrl: user.avatarUrl,
            name: user.name,
            size: avatarSize
        )
    }

    @ViewBuilder
    private var thoughtBubble: some View {
        let looking = (user.lookingFor ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        if !looking.isEmpty {
            bubble {
                Text(looking)
                    .font(.bodySmall)
                    .foregroundColor(.appPrimary)
                    .lineLimit(2)
            }
        } else if isSelf {
            Button(action: onEdit) {
                bubble {
                    Text("What are you looking for?")
                        .font(.bodySmall)
                        .foregroundColor(.appSecondary)
                }
            }
            .buttonStyle(.pressableScale(0.97))
        }
    }

    /// Compact thought bubble — rounded cloud with two thought dots flipped
    /// above the bubble's leading edge, nudged toward the middle.
    private func bubble<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                Color.appSurfaceSecondary,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(alignment: .leading) {
                Circle()
                    .fill(Color.appSurfaceSecondary)
                    .frame(width: 7, height: 7)
                    .offset(x: -8, y: 2)
            }
            .overlay(alignment: .leading) {
                Circle()
                    .fill(Color.appSurfaceSecondary)
                    .frame(width: 4, height: 4)
                    .offset(x: -15, y: -2)
            }
    }

    // MARK: - Name / Headline
    // Campus details live in the About tab — the header stays minimal.

    private var nameBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(user.name)
                .font(.heading2)
                .foregroundColor(.appPrimary)

            if let headline = user.headline, !headline.isEmpty {
                Text(headline)
                    .font(.body14)
                    .foregroundColor(.appPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Stat Line
    // One text style for all three — same font, same color, no opacity games.

    private var statLine: some View {
        HStack(spacing: Spacing.lg) {
            statText(postCount, postCount == 1 ? "post" : "posts", action: onTapPosts)
            statText(connectionCount, connectionCount == 1 ? "connection" : "connections")
            statText(vouchCount, vouchCount == 1 ? "vouch" : "vouches", action: onTapVouches)
        }
    }

    // A disabled SwiftUI Button auto-dims its label — which is why the
    // connections stat kept rendering at lower opacity. Non-tappable stats
    // are plain Text, never a disabled button.
    @ViewBuilder
    private func statText(_ count: Int, _ label: String, action: (() -> Void)? = nil) -> some View {
        let text = Text("\(count) \(label)")
            .font(.bodySmall)
            .foregroundColor(.appPrimary)

        if let action {
            Button(action: action) {
                text.contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            text
        }
    }

    // MARK: - Action Row
    // Always rendered — connection state updates in place, never hides the row.

    @ViewBuilder
    private var actionRow: some View {
        if isSelf {
            // Share lives in the top-right nav circle — one button is enough.
            solidButton("Edit Profile", action: onEdit)
        } else {
            HStack(spacing: Spacing.sm) {
                switch connectionStatus {
                case .none:
                    solidButton("Connect", icon: "status.add.fill", action: onConnect)
                        .disabled(isActioning)
                    secondaryButton("Message", icon: "tab.envelope.fill", action: onMessage)

                case .pendingSent:
                    secondaryButton("Pending", icon: "status.waiting.fill") {}
                        .disabled(true)
                    secondaryButton("Message", icon: "tab.envelope.fill", action: onMessage)

                case .pendingReceived:
                    solidButton("Accept", icon: "status.connection.fill", action: onAccept)
                        .disabled(isActioning)
                    secondaryButton("Message", icon: "tab.envelope.fill", action: onMessage)

                case .connected:
                    solidButton("Message", icon: "tab.envelope.fill", action: onMessage)
                    if hasVouched {
                        secondaryButton("Vouched") {}
                            .disabled(true)
                    } else {
                        secondaryButton("Vouch", action: onVouch)
                    }
                }
            }
        }
    }

    // MARK: - Button Styles

    private func solidButton(_ label: String, icon: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            buttonLabel(label, icon: icon)
                .foregroundColor(.appOnAccent)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(Color.appAccent)
                .clipShape(RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
        }
        .buttonStyle(.pressableScale(0.97))
    }

    private func secondaryButton(_ label: String, icon: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            buttonLabel(label, icon: icon)
                .foregroundColor(.appPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(Color.appSurfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
        }
        .buttonStyle(.pressableScale(0.97))
    }

    private func buttonLabel(_ label: String, icon: String?) -> some View {
        HStack(spacing: Spacing.xs) {
            if let icon {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
            }
            Text(label)
                .font(.bodySemibold)
        }
    }
}
