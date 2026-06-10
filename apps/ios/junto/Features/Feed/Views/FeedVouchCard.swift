//
//  FeedVouchCard.swift
//  junto
//
//  Social-proof "house" card — someone vouched for you. Mirrors FeedCard's
//  avatar + text-column layout, but with no connect badge and no FeedTypeLabel
//  (it isn't a taxonomy card). The voucher's note is the body. First pass.
//

import SwiftUI

struct FeedVouchCard: View {
    let vouch: VouchFeedResponse
    var onCardTap: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            AvatarView(
                avatarUrl: vouch.fromUser.avatarUrl,
                name: vouch.fromUser.name,
                size: 44
            )
            .frame(width: 44, height: 48, alignment: .top)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    header
                    Text("vouched for you")
                        .font(.body14)
                        .foregroundColor(.appSecondary)
                }

                Text("\u{201C}\(vouch.reason)\u{201D}")
                    .font(.bodyLargeMedium)
                    .foregroundColor(.appPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.lg)
        .background(Color.appSurface)
        .contentShape(Rectangle())
        .onTapGesture { onCardTap?() }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            Text(vouch.fromUser.name)
                .font(.caption12)
                .foregroundColor(.appPrimary)
            Text(vouch.createdDate.timeAgoShort())
                .font(.caption12)
                .foregroundColor(.appSecondary)
            Spacer(minLength: Spacing.sm)
            Text("Vouch")
                .font(.captionMedium)
                .foregroundColor(.appSecondary)
        }
    }
}
