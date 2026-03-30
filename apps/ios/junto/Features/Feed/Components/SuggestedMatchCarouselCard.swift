//
//  SuggestedMatchCarouselCard.swift
//  mkrs-world
//
//  Compact suggested match card for horizontal carousel
//

import SwiftUI

struct SuggestedMatchCarouselCard: View {
    let match: SuggestedMatchResponse
    var connectionStatus: ConnectionDisplayStatus = .none
    var onConnectTap: (() -> Void)? = nil
    var onWithdrawTap: (() -> Void)? = nil
    var onCardTap: (() -> Void)? = nil

    var body: some View {
        Button(action: { onCardTap?() }) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                // Avatar
                AvatarView(
                    avatarUrl: match.avatarUrl,
                    name: match.name,
                    size: 52
                )
                .padding(.bottom, Spacing.xxxs)

                // Name
                Text(match.name)
                    .font(.captionSemibold)
                    .foregroundColor(.appPrimary)
                    .lineLimit(1)

                // Headline
                if let headline = match.headline {
                    Text(headline)
                        .font(.caption12)
                        .foregroundColor(.appTertiary)
                        .lineLimit(1)
                }

                // Match reason — the key info, reserve 3 lines for uniform height
                ZStack(alignment: .topLeading) {
                    Text("L\nL\nL")
                        .font(.caption12)
                        .opacity(0)
                    Text(match.matchReason)
                        .font(.caption12)
                        .foregroundColor(.appSecondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)

                Spacer(minLength: 0)

                // CTA button
                ctaButton
            }
            .padding(Spacing.md)
            .frame(width: 160)
            .background(Color.appSurfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Radius.xxxl))
        }
        .buttonStyle(.plain)
    }

    // MARK: - CTA Button

    @ViewBuilder
    private var ctaButton: some View {
        switch connectionStatus {
        case .none:
            Button(action: { onConnectTap?() }) {
                Text("Connect")
                    .font(.captionSemibold)
                    .foregroundColor(.appOnAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.xs)
                    .background(Color.appPrimary)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

        case .connected:
            Text("Connected")
                .font(.captionSemibold)
                .foregroundColor(.appSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xs)
                .background(Color.appSurface)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.appDivider, lineWidth: 1))

        case .pending:
            Button(action: { onWithdrawTap?() }) {
                Text("Pending")
                    .font(.captionSemibold)
                    .foregroundColor(.appSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.xs)
                    .background(Color.appSurface)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.appDivider, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    SuggestedMatchCarouselCard(match: .mock)
        .padding()
        .background(Color.appBackground)
}
