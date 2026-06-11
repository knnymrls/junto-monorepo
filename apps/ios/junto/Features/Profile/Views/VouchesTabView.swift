//
//  VouchesTabView.swift
//  junto
//
//  Vouches tab — bordered vouch cards (voucher header + quote), matching the
//  app's bordered-card family (CategoryChip / Discover chips).
//

import SwiftUI
import Combine

struct VouchesTabView: View {
    let userId: String
    @State private var vouches: [VouchResponse] = []
    @State private var isLoading = true
    @State private var cancellable: AnyCancellable?

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView()
                    .tint(.appSecondary)
                    .padding(.top, Spacing.huge)
            } else if vouches.isEmpty {
                FeedMessageState(
                    icon: "feed.replies.empty",
                    title: "No vouches yet",
                    subtitle: "Vouches from collaborators show up here"
                )
            } else {
                LazyVStack(spacing: Spacing.md) {
                    ForEach(vouches) { vouch in
                        vouchCard(vouch)
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }
        }
        .padding(.bottom, Spacing.xxxl)
        .onAppear { startSubscription() }
        .onDisappear { cancellable?.cancel() }
    }

    // MARK: - Vouch Card

    private func vouchCard(_ vouch: VouchResponse) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                AvatarView(
                    avatarUrl: vouch.fromUser?.avatarUrl,
                    name: vouch.fromUser?.name ?? "?",
                    size: 32
                )

                Text(vouch.fromUser?.name ?? "Someone")
                    .font(.bodySemibold)
                    .foregroundColor(.appPrimary)

                Spacer(minLength: 0)

                Text(vouch.createdDate.timeAgoShort())
                    .font(.caption12)
                    .foregroundColor(.appSecondary)
            }

            Text("\u{201C}\(vouch.reason)\u{201D}")
                .font(.body14)
                .foregroundColor(.appPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.xxl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.xxl, style: .continuous)
                .strokeBorder(Color.appBorder, lineWidth: 1)
        )
    }

    // MARK: - Subscription

    private func startSubscription() {
        cancellable = ConvexClientManager.shared.subscribeVouches(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("VouchesTabView: subscription error: \(error)")
                        isLoading = false
                    }
                },
                receiveValue: { newVouches in
                    vouches = newVouches
                    isLoading = false
                }
            )
    }
}
