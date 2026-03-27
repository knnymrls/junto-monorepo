//
//  SearchResultCard.swift
//  mkrs-world
//
//  Compact card showing a search result with tokens and match explanation
//

import SwiftUI

struct SearchResultCard: View {
    let result: SearchResultItem
    let user: UserResponse
    let connectionStatus: ConnectionStatus
    let onViewProfile: () -> Void
    let onConnect: () -> Void
    var onTokenTap: ((String) -> Void)? = nil

    private var tokens: [String] {
        var items: [String] = []
        if let skills = user.skills {
            items.append(contentsOf: skills.prefix(4))
        }
        if items.count < 4, let interests = user.interests {
            let remaining = 4 - items.count
            items.append(contentsOf: interests.prefix(remaining))
        }
        return items
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Top row: avatar + name/headline + connect
            HStack(alignment: .top, spacing: Spacing.sm) {
                AvatarView(
                    avatarUrl: user.avatarUrl,
                    name: user.name,
                    size: 40
                )

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(user.name)
                        .font(.bodySemibold)
                        .foregroundColor(.appPrimary)

                    if let headline = user.headline {
                        Text(headline)
                            .font(.caption12)
                            .foregroundColor(.appSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                ConnectionButton(
                    status: connectionStatus,
                    style: .compact,
                    onConnect: onConnect
                )
            }

            // Mutual connections row
            if let count = result.mutualConnectionCount, count > 0 {
                mutualConnectionsRow(count: count, names: result.mutualConnectionNames ?? [])
            }

            // Skill/interest tokens
            if !tokens.isEmpty {
                FlowLayout(spacing: Spacing.xxs) {
                    ForEach(tokens, id: \.self) { token in
                        Button(action: {
                            onTokenTap?(token)
                        }) {
                            Text(token)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.appSecondary)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.xxxs)
                                .background(Color.appSurfaceSecondary)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            // AI explanation
            Text(result.explanation)
                .font(.body14)
                .foregroundColor(.appPrimary)
                .lineLimit(3)

            // View profile link
            HStack {
                Spacer()

                Button(action: onViewProfile) {
                    Text("View Profile")
                        .font(.caption12)
                        .foregroundColor(.appSecondary)
                }
            }
        }
        .padding(Spacing.sm)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
    }

    private func mutualConnectionsRow(count: Int, names: [String]) -> some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 10))
                .foregroundColor(.appSecondary)

            let countText = count == 1 ? "1 mutual" : "\(count) mutual"
            if names.isEmpty {
                Text(countText)
                    .font(.caption12)
                    .foregroundColor(.appSecondary)
            } else {
                let viaText = names.count == 1
                    ? "via \(names[0])"
                    : "via \(names[0]) & \(names[1])"
                Text("\(countText) \u{00B7} \(viaText)")
                    .font(.caption12)
                    .foregroundColor(.appSecondary)
            }
        }
    }
}
