//
//  VouchesTabView.swift
//  mkrs-world
//
//  Vouches tab — list of all vouches received by this user
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
                    .padding(.top, Spacing.huge)
            } else if vouches.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(vouches) { vouch in
                        vouchRow(vouch)
                        Divider()
                            .foregroundColor(.appDivider)
                    }
                }
            }
        }
        .padding(.bottom, Spacing.xxxl)
        .onAppear { startSubscription() }
        .onDisappear { cancellable?.cancel() }
    }

    // MARK: - Vouch Row

    private func vouchRow(_ vouch: VouchResponse) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            AvatarView(
                avatarUrl: vouch.fromUserAvatarUrl,
                name: vouch.fromUserName,
                size: 36
            )

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(vouch.fromUserName)
                    .font(.bodySemibold)
                    .foregroundColor(.appPrimary)

                Text("\"\(vouch.reason)\"")
                    .font(.body14)
                    .foregroundColor(.appPrimary)
                    .italic()

                Text(vouch.createdDate.timeAgoDisplay())
                    .font(.caption12)
                    .foregroundColor(.appTertiary)
                    .padding(.top, Spacing.xxxs)
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "hand.thumbsup")
                .font(.system(size: 32))
                .foregroundColor(.appSecondary)

            Text("No vouches yet")
                .font(.bodyLargeMedium)
                .foregroundColor(.appSecondary)

            Text("Vouches from collaborators will show up here.")
                .font(.body14)
                .foregroundColor(.appSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.huge)
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
