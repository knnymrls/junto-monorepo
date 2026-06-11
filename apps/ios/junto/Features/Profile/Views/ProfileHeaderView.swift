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
    var onShare: () -> Void = {}
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
        .padding(.top, Spacing.sm)
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
        }
    }

    private var avatarWithBadge: some View {
        ZStack(alignment: .bottomTrailing) {
            AvatarView(
                avatarUrl: user.avatarUrl,
                name: user.name,
                size: avatarSize
            )

            // The exact feed-card connect badge (AvatarAction geometry):
            // 22px surface ring → 18px dark disc → 10px Flex line icon.
            // Always present on other people; tap to connect / accept.
            if !isSelf {
                Button(action: badgeAction) {
                    ZStack {
                        Circle()
                            .fill(Color.appSurface)
                            .frame(width: 22, height: 22)
                        Circle()
                            .fill(Color.appPrimary)
                            .frame(width: 18, height: 18)
                        Image(badgeIconName)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 10, height: 10)
                            .foregroundColor(.appSurface)
                    }
                    .contentShape(Circle())
                }
                .buttonStyle(.pressableScale(0.85))
                .disabled(isActioning || connectionStatus == .pendingSent || connectionStatus == .connected)
                .offset(x: 4, y: 4)
            }
        }
    }

    private var badgeIconName: String {
        switch connectionStatus {
        case .connected: return "feed.connected"
        case .pendingSent, .pendingReceived: return "feed.clock"
        case .none: return "feed.connect"
        }
    }

    private func badgeAction() {
        switch connectionStatus {
        case .none: onConnect()
        case .pendingReceived: onAccept()
        default: break
        }
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

    /// Compact thought bubble — rounded cloud with two trailing thought dots
    /// drifting back toward the avatar.
    private func bubble<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                Color.appSurfaceSecondary,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(alignment: .bottomLeading) {
                Circle()
                    .fill(Color.appSurfaceSecondary)
                    .frame(width: 7, height: 7)
                    .offset(x: -7, y: 3)
            }
            .overlay(alignment: .bottomLeading) {
                Circle()
                    .fill(Color.appSurfaceSecondary)
                    .frame(width: 4, height: 4)
                    .offset(x: -14, y: 8)
            }
    }

    // MARK: - Name / Headline / Campus

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

            if let campus = campusLine {
                HStack(spacing: Spacing.xs) {
                    if let logoUrl = context?.university?.logoUrl, let url = URL(string: logoUrl) {
                        CachedAsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Color.clear
                        }
                        .frame(width: 14, height: 14)
                        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                    }

                    Text(campus)
                        .font(.bodySmall)
                        .foregroundColor(.appSecondary)
                        .lineLimit(1)
                }
                .padding(.top, Spacing.xxxs)
            }
        }
    }

    /// "UNL · Computer Science · Fall 2026"
    private var campusLine: String? {
        var parts: [String] = []
        if let university = context?.university {
            parts.append(university.shortName ?? university.name)
        }
        if let major = context?.majorNames.first {
            parts.append(major)
        }
        if let grad = user.graduationSemester, !grad.isEmpty {
            parts.append(grad)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
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

    private func statText(_ count: Int, _ label: String, action: (() -> Void)? = nil) -> some View {
        Button(action: { action?() }) {
            Text("\(count) \(label)")
                .font(.bodySmall)
                .foregroundColor(.appPrimary)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }

    // MARK: - Action Row
    // Always rendered — connection state updates in place, never hides the row.

    @ViewBuilder
    private var actionRow: some View {
        if isSelf {
            HStack(spacing: Spacing.sm) {
                solidButton("Edit Profile", action: onEdit)
                secondaryButton("Share Profile", action: onShare)
            }
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
