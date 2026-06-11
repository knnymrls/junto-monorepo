//
//  ProfileHeaderView.swift
//  junto
//
//  Profile hero — avatar with the feed-style connection badge, a "looking
//  for" speech bubble rising off the avatar and spreading right, name /
//  headline / campus, an inline text stat row (posts · connections · vouches
//  — Junto has no followers), category chips, and action buttons.
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
    let isLoadingStatus: Bool
    @Binding var isActioning: Bool

    var onEdit: () -> Void = {}
    var onShare: () -> Void = {}
    var onVouch: () -> Void = {}
    var onMessage: () -> Void = {}
    var onConnect: () -> Void = {}
    var onAccept: () -> Void = {}
    var onTapPosts: () -> Void = {}
    var onTapVouches: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            avatarBubbleRow

            nameBlock

            statLine

            if !categoryChips.isEmpty || !(user.programs ?? []).isEmpty {
                chipRow
            }

            if !isLoadingStatus {
                actionRow
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.md)
    }

    // MARK: - Avatar + Looking-For Bubble

    private var avatarBubbleRow: some View {
        HStack(spacing: 0) {
            avatarWithBadge
            Spacer(minLength: 0)
        }
        // Headroom for a tall bubble — it grows upward from the anchor without
        // ever moving the avatar or the rest of the hero.
        .padding(.top, Spacing.lg)
        // The bubble is absolutely placed off the avatar (overlay, not layout):
        // anchored low on the avatar's shoulder, spreading right.
        .overlay(alignment: .bottomLeading) {
            lookingForBubble
                .padding(.leading, 84 + Spacing.md)
                .padding(.bottom, Spacing.sm)
                .allowsHitTesting(true)
        }
    }

    private var avatarWithBadge: some View {
        ZStack(alignment: .bottomTrailing) {
            AvatarView(
                avatarUrl: user.avatarUrl,
                name: user.name,
                size: 84
            )

            // Feed-family connect badge, scaled up for the hero avatar.
            // This IS the connect control on profile.
            if !isSelf && !isLoadingStatus {
                Button(action: badgeAction) {
                    connectionBadge
                }
                .buttonStyle(.pressableScale(0.85))
                .disabled(isActioning || connectionStatus == .pendingSent)
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

    // 30px ring (surface) → 26px dark disc → 14px Flex line icon — the
    // FeedPostCard badge geometry scaled to the 84pt avatar.
    private var connectionBadge: some View {
        ZStack {
            Circle()
                .fill(Color.appSurface)
                .frame(width: 30, height: 30)
            Circle()
                .fill(Color.appPrimary)
                .frame(width: 26, height: 26)
            Image(badgeIconName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)
                .foregroundColor(.appSurface)
        }
        .contentShape(Circle())
    }

    @ViewBuilder
    private var lookingForBubble: some View {
        let looking = (user.lookingFor ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        if !looking.isEmpty {
            bubble {
                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    Text("LOOKING FOR")
                        .font(.microSemibold)
                        .foregroundColor(.appSecondary)

                    Text(looking)
                        .font(.body14)
                        .foregroundColor(.appPrimary)
                        .lineLimit(3)
                }
            }
        } else if isSelf {
            Button(action: onEdit) {
                bubble {
                    Text("What are you looking for?")
                        .font(.body14)
                        .foregroundColor(.appSecondary)
                }
            }
            .buttonStyle(.pressableScale(0.97))
        }
    }

    /// Message-bubble treatment from the chat surface: 18pt corners with a
    /// tight bottom-leading corner as the tail pointing back at the avatar.
    private func bubble<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color.appSurfaceSecondary,
                in: UnevenRoundedRectangle(
                    topLeadingRadius: 18,
                    bottomLeadingRadius: 4,
                    bottomTrailingRadius: 18,
                    topTrailingRadius: 18,
                    style: .continuous
                )
            )
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

    // MARK: - Stat Line (X-style inline text counts)

    private var statLine: some View {
        HStack(spacing: Spacing.lg) {
            statText(postCount, postCount == 1 ? "post" : "posts", action: onTapPosts)
            statText(connectionCount, connectionCount == 1 ? "connection" : "connections")
            statText(vouchCount, vouchCount == 1 ? "vouch" : "vouches", action: onTapVouches)
        }
    }

    // One text style across all three stats — same font, same color.
    private func statText(_ count: Int, _ label: String, action: (() -> Void)? = nil) -> some View {
        Button(action: { action?() }) {
            Text("\(count) \(label)")
                .font(.bodySmall)
                .foregroundColor(.appSecondary)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }

    // MARK: - Category Chips

    /// Maker categories — derived skillCategories first, then matched from
    /// resolved skill names. Raw IDs never render.
    private var categoryChips: [SkillCategory] {
        var seen = Set<SkillCategory>()
        var result: [SkillCategory] = []
        let sources = (user.skillCategories ?? []) + (context?.skillNames ?? [])
        for raw in sources {
            guard let category = SkillCategory.match(raw), seen.insert(category).inserted else { continue }
            result.append(category)
            if result.count == 4 { break }
        }
        return result
    }

    private var chipRow: some View {
        FlowLayout(spacing: Spacing.xs) {
            ForEach(categoryChips, id: \.self) { category in
                chip(label: category.label, icon: category.icon, iconColor: category.color)
            }

            // Programs (Raikes School, Accelerator, …) ride alongside the
            // maker categories as plain chips.
            ForEach(user.programs ?? [], id: \.self) { program in
                chip(label: program)
            }
        }
    }

    private func chip(label: String, icon: String? = nil, iconColor: Color = .appPrimary) -> some View {
        HStack(spacing: Spacing.xxs) {
            if let icon {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .foregroundColor(iconColor)
            }

            Text(label)
                .font(.bodySmallMedium)
                .foregroundColor(.appPrimary)
        }
        .padding(.horizontal, Spacing.sm + Spacing.xxs)
        .padding(.vertical, Spacing.xs)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .strokeBorder(Color.appBorder, lineWidth: 1)
        )
    }

    // MARK: - Action Row
    // Connect lives on the avatar badge; the buttons handle everything else.

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
    // Solid = accent fill (the app's filled-action treatment); secondary =
    // the frosted appSurfaceSecondary chip used by the nav circles + tab pill.

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
