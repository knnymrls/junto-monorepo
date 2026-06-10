//
//  AskJuntoPersonCard.swift
//  junto
//
//  Compact person card for an Ask Junto `people` block — a fixed-width tile in
//  a horizontal strip (Figma node 148-31). Avatar (+ connect badge), name, and
//  up to two skill-category tags. Reuses AvatarAction + TopicTag.
//

import SwiftUI

struct AskJuntoPersonCard: View {
    let user: UserResponse
    var connectionStatus: ConnectionStatus = .none
    var isSelf: Bool = false
    var onTap: (() -> Void)? = nil
    var onConnect: (() -> Void)? = nil
    var profileZoomID: AnyHashable? = nil
    var profileZoomNamespace: Namespace.ID? = nil

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            AvatarAction(
                avatarUrl: user.avatarUrl,
                name: user.name,
                size: 44,
                connectionStatus: displayStatus,
                isOwnPost: isSelf,
                onAvatarTap: { onTap?() },
                onConnectTap: { onConnect?() },
                zoomID: profileZoomID,
                zoomNamespace: profileZoomNamespace
            )
            .frame(width: 44, height: 48)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(user.name)
                    .font(.bodyLargeSemibold)
                    .foregroundColor(.appPrimary)
                    .lineLimit(1)

                if !tags.isEmpty {
                    HStack(spacing: Spacing.sm) {
                        ForEach(tags, id: \.self) { tag in
                            TopicTag(category: tag)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        // Width-fit: the card hugs its content (avatar + name + tags).
        .fixedSize(horizontal: true, vertical: false)
        .background(Color.appSurfaceSecondary, in: RoundedRectangle(cornerRadius: Radius.xxl))
        .contentShape(RoundedRectangle(cornerRadius: Radius.xxl))
        .onTapGesture { onTap?() }
    }

    /// Up to two skill categories — derived field first, else matched from
    /// the person's raw skills/interests (raw strings never leak in).
    private var tags: [String] {
        if let cats = user.skillCategories, !cats.isEmpty {
            return Array(cats.prefix(2))
        }
        var seen = Set<SkillCategory>()
        var labels: [String] = []
        for raw in (user.skills ?? []) + (user.interests ?? []) {
            guard let category = SkillCategory.match(raw), seen.insert(category).inserted else { continue }
            labels.append(category.label)
            if labels.count == 2 { break }
        }
        return labels
    }

    private var displayStatus: ConnectionDisplayStatus {
        switch connectionStatus {
        case .connected: return .connected
        case .pendingSent, .pendingReceived: return .pending
        case .none: return .none
        }
    }
}

/// Shimmer placeholder shown in a people strip while a profile is loading.
struct AskJuntoPersonCardSkeleton: View {
    var body: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            SkeletonCircle(size: 44)
                .frame(width: 44, height: 48)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                SkeletonShape(width: 96, height: 16)
                HStack(spacing: Spacing.sm) {
                    SkeletonShape(width: 52, height: 14, cornerRadius: 6)
                    SkeletonShape(width: 44, height: 14, cornerRadius: 6)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .frame(width: 200, alignment: .leading)
        .background(Color.appSurfaceSecondary, in: RoundedRectangle(cornerRadius: Radius.xxl))
    }
}
