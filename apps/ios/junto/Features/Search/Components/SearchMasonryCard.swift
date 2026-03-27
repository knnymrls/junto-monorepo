//
//  SearchMasonryCard.swift
//  mkrs-world
//
//  Compact masonry card for search results with entrance animation
//

import SwiftUI

struct SearchMasonryCard: View {
    let result: SearchResultItem
    let user: UserResponse
    let connectionStatus: ConnectionStatus
    let onTap: () -> Void
    let onConnect: () -> Void
    var appearDelay: Double = 0
    var isEnhancing: Bool = false

    @State private var isVisible = false

    private var skillTags: [String] {
        var items: [String] = []
        if let skills = user.skills {
            items.append(contentsOf: skills.prefix(3))
        }
        if items.count < 3, let interests = user.interests {
            items.append(contentsOf: interests.prefix(3 - items.count))
        }
        return items
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Header: avatar + name + headline
                HStack(spacing: Spacing.xs) {
                    AvatarView(
                        avatarUrl: user.avatarUrl,
                        name: user.name,
                        size: 32
                    )

                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: Spacing.xxxs) {
                            Text(user.name)
                                .font(.bodySemibold)
                                .foregroundColor(.appPrimary)
                                .lineLimit(1)

                            if result.isAIEnhanced == true || isEnhancing {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 8))
                                    .foregroundColor(.appSecondary)
                                    .symbolEffect(.pulse, options: .repeating, isActive: isEnhancing)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }

                        if let headline = user.headline {
                            Text(headline)
                                .font(.caption12)
                                .foregroundColor(.appSecondary)
                                .lineLimit(1)
                        }
                    }
                }

                // Explanation text — shimmer while enhancing, crossfade on arrival
                if isEnhancing {
                    VStack(alignment: .leading, spacing: Spacing.xxxs) {
                        SkeletonShape(height: 10)
                        SkeletonShape(width: 80, height: 10)
                    }
                } else if result.explanation.lowercased() != (user.headline ?? "").lowercased() {
                    Text(result.explanation)
                        .font(.caption12)
                        .foregroundColor(.appSecondary)
                        .lineLimit(2)
                        .id(result.explanation)
                        .transition(.opacity)
                }

                // Skill tags
                if !skillTags.isEmpty {
                    FlowLayout(spacing: Spacing.xxxs) {
                        ForEach(skillTags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.appSecondary)
                                .padding(.horizontal, Spacing.xs)
                                .padding(.vertical, 2)
                                .background(Color.appSurfaceSecondary)
                                .clipShape(Capsule())
                        }
                    }
                }

                // Bottom row: mutual connections + connect button
                HStack {
                    if let count = result.mutualConnectionCount, count > 0 {
                        HStack(spacing: Spacing.xxxs) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 9))
                            Text("\(count) mutual")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(.appSecondary)
                    }

                    Spacer()

                    ConnectionButton(
                        status: connectionStatus,
                        style: .compact,
                        onConnect: onConnect
                    )
                }
            }
            .padding(Spacing.sm)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .stroke(Color.appDivider, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(appearDelay)) {
                isVisible = true
            }
        }
        .animation(.easeInOut(duration: 0.3), value: result.explanation)
        .animation(.easeInOut(duration: 0.3), value: result.isAIEnhanced)
        .animation(.easeInOut(duration: 0.3), value: isEnhancing)
    }
}
