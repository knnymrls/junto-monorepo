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

            actionRow
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.md)
    }

    // MARK: - Avatar + Stats

    private var avatarBubbleRow: some View {
        HStack(alignment: .center, spacing: Spacing.lg) {
            AvatarView(
                avatarUrl: user.avatarUrl,
                name: user.name,
                size: avatarSize
            )

            // Name stacked over the stats, flexing to fill the right side.
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(user.name)
                    .font(.heading2)
                    .foregroundColor(.appPrimary)
                    .lineLimit(1)

                HStack(spacing: Spacing.sm) {
                    statColumn(postCount, postCount == 1 ? "Post" : "Posts", action: onTapPosts)
                    statColumn(connectionCount, connectionCount == 1 ? "Connection" : "Connections")
                    statColumn(vouchCount, vouchCount == 1 ? "Vouch" : "Vouches", action: onTapVouches)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // Plain views wrapped in a Button only when tappable — a disabled Button
    // auto-dims its label, which made the stats render in mismatched colors.
    @ViewBuilder
    private func statColumn(_ count: Int, _ label: String, action: (() -> Void)? = nil) -> some View {
        // Each column flexes to an equal share of the row's width.
        let column = VStack(alignment: .leading, spacing: Spacing.xxxs) {
            Text("\(count)")
                .font(.bodyLargeBold)
                .foregroundColor(.appPrimary)

            Text(label)
                .font(.caption12)
                .foregroundColor(.appSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        if let action {
            Button(action: action) {
                column.contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            column
        }
    }

    // MARK: - Headline / Campus
    // The name sits up in the identity row, stacked over the stats.

    private var nameBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
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
