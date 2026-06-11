//
//  ProfileHeaderView.swift
//  junto
//
//  Profile hero — left-aligned identity block (avatar + stat columns), name,
//  headline, campus line, maker-category chips, action buttons, and the maker
//  card (Building / Can help with / Looking for). Junto has no followers; the
//  stats are posts, connections, and vouches. Reads as the same family as the
//  Feed cards and Discover chips.
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
            identityRow

            nameBlock

            if !categoryChips.isEmpty {
                chipRow
            }

            if !isLoadingStatus {
                actionRow
            }

            makerCard
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.md)
    }

    // MARK: - Identity Row (avatar + stats)

    private var identityRow: some View {
        HStack(alignment: .center, spacing: Spacing.lg) {
            AvatarView(
                avatarUrl: user.avatarUrl,
                name: user.name,
                size: 84
            )

            Spacer(minLength: Spacing.lg)

            HStack(spacing: 0) {
                statColumn(count: postCount, label: "Posts", action: onTapPosts)
                statColumn(count: connectionCount, label: "Connections")
                statColumn(count: vouchCount, label: "Vouches", action: onTapVouches)
            }
        }
    }

    private func statColumn(count: Int, label: String, action: (() -> Void)? = nil) -> some View {
        Button(action: { action?() }) {
            VStack(spacing: Spacing.xxxs) {
                Text("\(count)")
                    .font(.heading2)
                    .foregroundColor(.appPrimary)
                    .contentTransition(.numericText())

                Text(label)
                    .font(.caption12)
                    .foregroundColor(.appSecondary)
            }
            .frame(minWidth: 64)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
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
                HStack(spacing: Spacing.xxs) {
                    Image(category.icon)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundColor(category.color)

                    Text(category.label)
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
        }
    }

    // MARK: - Action Row

    @ViewBuilder
    private var actionRow: some View {
        if isSelf {
            HStack(spacing: Spacing.sm) {
                solidButton("Edit Profile", action: onEdit)
                secondaryButton("Share Profile", action: onShare)
            }
        } else {
            HStack(spacing: Spacing.sm) {
                connectionButton

                if connectionStatus == .connected {
                    if hasVouched {
                        secondaryButton("Vouched") {}
                            .disabled(true)
                    } else {
                        solidButton("Vouch", action: onVouch)
                    }
                }

                iconButton("tab.envelope.fill", action: onMessage)
            }
        }
    }

    @ViewBuilder
    private var connectionButton: some View {
        switch connectionStatus {
        case .none:
            solidButton("Connect", icon: "status.add.fill", action: onConnect)
                .disabled(isActioning)
        case .pendingSent:
            secondaryButton("Pending", icon: "status.waiting.fill") {}
                .disabled(true)
        case .pendingReceived:
            solidButton("Accept", icon: "status.connection.fill", action: onAccept)
                .disabled(isActioning)
        case .connected:
            secondaryButton("Connected", icon: "status.connection.fill") {}
                .disabled(true)
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

    private func iconButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundColor(.appPrimary)
                .frame(width: 48, height: 42)
                .background(Color.appSurfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
        }
        .buttonStyle(.pressableScale(0.9))
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

    // MARK: - Maker Card
    // The PRD's trust core: "what I can help with" lives on the profile and the
    // system turns it into Matches. Building / Can help with / Looking for.

    private struct MakerRow: Identifiable {
        let id: String
        let icon: String
        let title: String
        let text: String
    }

    private var makerRows: [MakerRow] {
        var rows: [MakerRow] = []
        if let building = user.currentProject, !building.isEmpty {
            rows.append(MakerRow(id: "building", icon: "content.update", title: "Building", text: building))
        }
        if let help = user.canHelpWith, !help.isEmpty {
            rows.append(MakerRow(id: "help", icon: "content.sharing", title: "Can help with", text: help))
        }
        if let looking = user.lookingFor, !looking.isEmpty {
            rows.append(MakerRow(id: "looking", icon: "content.looking", title: "Looking for", text: looking))
        }
        return rows
    }

    @ViewBuilder
    private var makerCard: some View {
        if !makerRows.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(makerRows.enumerated()), id: \.element.id) { index, row in
                    makerRowView(row)

                    if index < makerRows.count - 1 {
                        Rectangle()
                            .fill(Color.appDivider)
                            .frame(height: 1 / UIScreen.main.scale)
                            .padding(.leading, Spacing.lg + 32 + Spacing.md)
                    }
                }
            }
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.xxl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.xxl, style: .continuous)
                    .strokeBorder(Color.appBorder, lineWidth: 1)
            )
        } else if isSelf {
            Button(action: onEdit) {
                HStack(spacing: Spacing.md) {
                    Image("content.sharing")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundColor(.appSecondary)
                        .frame(width: 32, height: 32)
                        .background(Color.appSurfaceSecondary)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: Spacing.xxxs) {
                        Text("Add what you can help with")
                            .font(.bodySemibold)
                            .foregroundColor(.appPrimary)
                        Text("Junto turns it into matches when someone needs you")
                            .font(.bodySmall)
                            .foregroundColor(.appSecondary)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.appSecondary)
                }
                .padding(Spacing.lg)
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.xxl, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.xxl, style: .continuous)
                        .strokeBorder(Color.appBorder, lineWidth: 1)
                )
                .contentShape(RoundedRectangle(cornerRadius: Radius.xxl, style: .continuous))
            }
            .buttonStyle(.pressableScale(0.98))
        }
    }

    private func makerRowView(_ row: MakerRow) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(row.icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundColor(.appPrimary)
                .frame(width: 32, height: 32)
                .background(Color.appSurfaceSecondary)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(row.title.uppercased())
                    .font(.captionSmallSemibold)
                    .foregroundColor(.appSecondary)

                Text(row.text)
                    .font(.body14)
                    .foregroundColor(.appPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
    }
}
