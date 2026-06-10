//
//  DiscoverPersonCard.swift
//  junto
//
//  "People you should know" row for Discover. Mirrors the Feed's unified card
//  layout — avatar (+ connect badge), name, a help/looking line, and category
//  tags — but is sourced from a UserResponse suggestion rather than a feed
//  item. Matches the Discover artboard's people card (Paper 7ZX-0 list).
//

import SwiftUI

struct DiscoverPersonCard: View {
    let user: UserResponse
    var connectionStatus: ConnectionStatus = .none
    var isSelf: Bool = false
    var onTap: (() -> Void)? = nil
    var onConnect: (() -> Void)? = nil
    var onDisconnect: (() -> Void)? = nil
    var profileZoomID: AnyHashable? = nil
    var profileZoomNamespace: Namespace.ID? = nil

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            AvatarAction(
                avatarUrl: user.avatarUrl,
                name: user.name,
                size: 44,
                connectionStatus: displayStatus,
                isOwnPost: isSelf,
                onAvatarTap: { onTap?() },
                onConnectTap: { onConnect?() },
                onDisconnectTap: { onDisconnect?() },
                zoomID: profileZoomID,
                zoomNamespace: profileZoomNamespace
            )
            .frame(width: 44, height: 48)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(user.name)
                        .font(.caption12)
                        .foregroundColor(.appPrimary)

                    Text(bodyText)
                        .font(.bodyLargeMedium)
                        .foregroundColor(.appPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if !tags.isEmpty {
                    FlowLayout(spacing: Spacing.xs) {
                        ForEach(tags, id: \.self) { tag in
                            TopicTag(category: tag)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.lg)
        .background(Color.appSurface)
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
    }

    // MARK: - Derived content

    /// Best one-liner describing the person — what they can help with, else
    /// what they're looking for, else their headline.
    private var bodyText: String {
        let candidates = [user.canHelpWith, user.lookingFor, user.currentProject, user.headline]
        return candidates
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty })
            ?? "Maker on campus"
    }

    /// Up to three distinct skill categories (with icons), derived from the
    /// person's skills then interests. Only mapped categories are shown — raw
    /// skill strings (which may be IDs) never leak into the tag row.
    private var tags: [String] {
        // Real maker categories derived on the backend. Fall back to matching
        // raw skill strings only if the derived field hasn't populated yet.
        if let cats = user.skillCategories, !cats.isEmpty {
            return Array(cats.prefix(3))
        }
        var seen = Set<SkillCategory>()
        var labels: [String] = []
        for raw in (user.skills ?? []) + (user.interests ?? []) {
            guard let category = SkillCategory.match(raw), seen.insert(category).inserted else { continue }
            labels.append(category.label)
            if labels.count == 3 { break }
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
