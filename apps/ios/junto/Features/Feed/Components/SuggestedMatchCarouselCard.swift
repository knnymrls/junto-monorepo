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
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    // Header row: avatar + name/headline
                    HStack(spacing: Spacing.xxs) {
                        AvatarView(
                            avatarUrl: match.avatarUrl,
                            name: match.name,
                            size: 36
                        )

                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text(match.name)
                                .font(.captionMedium)
                                .foregroundColor(.appPrimary)
                                .lineLimit(1)

                            if let headline = match.headline {
                                Text(headline)
                                    .font(.caption12)
                                    .foregroundColor(.appSecondary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Match reason — full text, no truncation
                    Text(match.matchReason)
                        .font(.bodyMedium)
                        .foregroundColor(.appPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                ctaButton
            }
            .padding(Spacing.md)
            .frame(width: 175)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.xxl))
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
                    .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
            }
            .buttonStyle(.plain)

        case .connected:
            Text("Connected")
                .font(.captionSemibold)
                .foregroundColor(.appSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.xl)
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
                    .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.xl)
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
