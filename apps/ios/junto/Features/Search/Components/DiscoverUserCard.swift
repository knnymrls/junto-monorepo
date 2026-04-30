//
//  DiscoverUserCard.swift
//  mkrs-world
//
//  Masonry card used by the Search/Discover idle grid. Mirrors the layout
//  of SuggestedMatchCarouselCard ("People you should know") but takes a
//  UserResponse and uses ConnectionStatus from the search infra.
//

import SwiftUI

struct DiscoverUserCard: View {
    let user: UserResponse
    let connectionStatus: ConnectionStatus
    /// AI-generated short explanation for why this person matches the
    /// current search query. When non-nil, replaces the fallback profile
    /// text (lookingFor / project / etc.) so the card reflects the
    /// reasoning behind the match.
    var explanation: String? = nil
    var isEnhancing: Bool = false
    let onTap: () -> Void
    let onConnect: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack(spacing: Spacing.xxs) {
                        AvatarView(
                            avatarUrl: user.avatarUrl,
                            name: user.name,
                            size: 36
                        )

                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text(user.name)
                                .font(.captionMedium)
                                .foregroundColor(.appPrimary)
                                .lineLimit(1)

                            if let headline = user.headline, !headline.isEmpty {
                                Text(headline)
                                    .font(.caption12)
                                    .foregroundColor(.appSecondary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if isEnhancing {
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            SkeletonShape(height: 14)
                            SkeletonShape(width: 140, height: 14)
                            SkeletonShape(width: 90, height: 14)
                        }
                    } else {
                        Text(displayText)
                            .font(.bodyMedium)
                            .foregroundColor(.appPrimary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                ctaButton
            }
            .padding(Spacing.md)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.xxl))
        }
        .buttonStyle(.plain)
    }

    private var displayText: String {
        if let explanation, !explanation.isEmpty { return explanation }
        if let lookingFor = user.lookingFor, !lookingFor.isEmpty { return lookingFor }
        if let project = user.currentProject, !project.isEmpty { return project }
        if let canHelpWith = user.canHelpWith, !canHelpWith.isEmpty { return "Can help with \(canHelpWith)" }
        if let headline = user.headline, !headline.isEmpty { return headline }
        return "Building things on campus"
    }

    @ViewBuilder
    private var ctaButton: some View {
        switch connectionStatus {
        case .none, .pendingReceived:
            Button(action: onConnect) {
                Text("Connect")
                    .font(.captionSemibold)
                    .foregroundColor(.appOnAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.appPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
            }
            .buttonStyle(.plain)

        case .connected:
            Text("Connected")
                .font(.captionSemibold)
                .foregroundColor(.appSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background(Color.appSurfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Radius.xl))

        case .pendingSent:
            Text("Pending")
                .font(.captionSemibold)
                .foregroundColor(.appSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background(Color.appSurfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
        }
    }
}

// MARK: - Skeleton

struct DiscoverUserCardSkeleton: View {
    var height: CGFloat = 170

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: Spacing.xxs) {
                    SkeletonCircle(size: 36)
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        SkeletonShape(width: 80, height: 12)
                        SkeletonShape(width: 60, height: 10)
                    }
                    Spacer(minLength: 0)
                }

                SkeletonShape(height: 14)
                SkeletonShape(width: 120, height: 14)
            }

            SkeletonShape(height: 32, cornerRadius: Radius.xl)
        }
        .padding(Spacing.md)
        .frame(height: height)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.xxl))
    }
}
