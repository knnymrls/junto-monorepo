//
//  SuggestedConnectionsView.swift
//  junto
//
//  Onboarding step 8: suggested connections at your university
//

import SwiftUI

struct SuggestedConnectionsView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var cardsAppeared = false

    private let rotations: [Double] = [1, -2, 2, -1]

    var body: some View {
        VStack(spacing: Spacing.jumbo) {
            Spacer()

            Text("Here are some people you may know!")
                .font(.juntoHeading)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xxl)
                .staggeredAppear(delay: 0.1)

            // 2x2 grid of cards
            if viewModel.suggestedConnections.isEmpty {
                Text("Finding people at your campus...")
                    .font(.bodyLarge)
                    .foregroundColor(.white.opacity(0.8))
            } else {
                let columns = [
                    GridItem(.flexible(), spacing: Spacing.md),
                    GridItem(.flexible(), spacing: Spacing.md),
                ]
                LazyVGrid(columns: columns, spacing: Spacing.lg) {
                    ForEach(Array(viewModel.suggestedConnections.enumerated()), id: \.element.id) { index, connection in
                        ConnectionCard(
                            connection: connection,
                            isSent: viewModel.sentConnectionIds.contains(connection.id),
                            onConnect: {
                                Task { await viewModel.sendConnectionRequest(to: connection.id) }
                            }
                        )
                        .rotationEffect(.degrees(cardsAppeared ? rotations[index % rotations.count] : 0))
                        .opacity(cardsAppeared ? 1 : 0)
                        .offset(y: cardsAppeared ? 0 : 30)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.12),
                            value: cardsAppeared
                        )
                    }
                }
                .padding(.horizontal, Spacing.xxl)
            }

            Spacer()

            PrimaryButton(title: "Let's go!", isEnabled: true) {
                viewModel.advance()
            }
            .padding(.horizontal, Spacing.xxl)
            .padding(.bottom, Spacing.lg)
            .staggeredAppear(delay: 0.5)
        }
        .task {
            await viewModel.loadSuggestedConnections()
            withAnimation { cardsAppeared = true }
        }
        .onAppear {
            AnalyticsService.shared.track(.onboardingStepViewed(step: 8, stepName: "suggested_connections"))
        }
    }
}

// MARK: - Connection Card

private struct ConnectionCard: View {
    let connection: SuggestedConnection
    let isSent: Bool
    let onConnect: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            VStack(spacing: Spacing.sm) {
                HStack(spacing: Spacing.xs) {
                    if let url = connection.avatarUrl, let imageUrl = URL(string: url) {
                        AsyncImage(url: imageUrl) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Circle()
                                .fill(Color.appInputFill)
                        }
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.appSecondary, Color.appInputFill)
                            .frame(width: 36, height: 36)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(connection.name)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.appPrimary)
                            .lineLimit(1)

                        Text(connection.headline)
                            .font(.system(size: 12))
                            .foregroundColor(.appSecondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)
                }

                if !connection.lookingFor.isEmpty {
                    Text(connection.lookingFor)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.appPrimary)
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Button(action: onConnect) {
                Text(isSent ? "Sent!" : "Connect")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isSent ? .appSecondary : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(isSent ? Color.appInputFill : Color.appAccent)
                    .clipShape(Capsule())
            }
            .disabled(isSent)
            .scaleEffect(isSent ? 1.0 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSent)
        }
        .padding(Spacing.md)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: Radius.xxxl))
    }
}
