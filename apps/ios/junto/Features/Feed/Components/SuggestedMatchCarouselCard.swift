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
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Top: Avatar + name/headline
                HStack(spacing: Spacing.xxs) {
                    AvatarView(
                        avatarUrl: match.avatarUrl,
                        name: match.name,
                        size: 36
                    )

                    VStack(alignment: .leading, spacing: 0) {
                        Text(match.name)
                            .font(.captionMedium)
                            .foregroundColor(.appPrimary)
                            .lineLimit(1)

                        if let headline = match.headline {
                            Text(headline)
                                .font(.caption12)
                                .foregroundColor(.appSecondary)
                                .lineLimit(1)
                        }
                    }
                }

                // Match reason — always reserves 3 lines of space
                ZStack(alignment: .topLeading) {
                    Text("L\nL\nL")
                        .font(.bodyLargeMedium)
                        .opacity(0)
                    Text(match.matchReason)
                        .font(.bodyLargeMedium)
                        .foregroundColor(.appPrimary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)

                // CTA button
                ctaButton
            }
            .padding(Spacing.md)
            .frame(width: 200)
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
                    .padding(.vertical, Spacing.sm)
                    .background(Color.appPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
            }
            .buttonStyle(.plain)

        case .connected:
            Text("Connected")
                .font(.captionSemibold)
                .foregroundColor(.appSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.appDivider, lineWidth: 1)
                )

        case .pending:
            Button(action: { onWithdrawTap?() }) {
                Text("Pending")
                    .font(.captionSemibold)
                    .foregroundColor(.appSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.appSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.appDivider, lineWidth: 1)
                    )
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
