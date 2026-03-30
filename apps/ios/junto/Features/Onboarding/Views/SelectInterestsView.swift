//
//  SelectInterestsView.swift
//  junto
//
//  Onboarding step 6: search and select interests
//

import SwiftUI

struct SelectInterestsView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Title
            Text("What are your interests?")
                .font(.juntoHeading)
                .foregroundColor(.appPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.xxl)
                .padding(.top, Spacing.jumbo)

            // Search
            JuntoTextField(
                placeholder: "Search for an interest...",
                text: $viewModel.interestSearch,
                icon: Image(systemName: "magnifyingglass")
            )
            .padding(.horizontal, Spacing.xxl)
            .padding(.top, Spacing.lg)

            // Chips
            ZStack {
                ScrollView {
                    FlowLayout(spacing: Spacing.sm, centered: true) {
                        ForEach(viewModel.interestResults) { interest in
                            Button {
                                viewModel.toggleInterest(interest)
                            } label: {
                                SelectableChip(
                                    title: interest.name,
                                    isSelected: viewModel.selectedInterestIds.contains(interest.id)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.lg)
                    .padding(.bottom, Spacing.huge)
                }
                .scrollIndicators(.hidden)

                // Gradient fades
                VStack {
                    LinearGradient(
                        colors: [Color.appBackground, Color.appBackground.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 16)

                    Spacer()

                    LinearGradient(
                        colors: [Color.appBackground.opacity(0), Color.appBackground],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 24)
                }
                .allowsHitTesting(false)
            }

            // Continue
            PrimaryButton(
                title: "Continue",
                isEnabled: !viewModel.selectedInterestIds.isEmpty
            ) {
                viewModel.advance()
            }
            .padding(.horizontal, Spacing.xxl)
            .padding(.bottom, Spacing.lg)
        }
        .onChange(of: viewModel.interestSearch) { _, query in
            viewModel.searchInterests(query)
        }
        .task { await viewModel.loadInterests() }
        .onAppear { AnalyticsService.shared.track(.onboardingStepViewed(step: 6, stepName: "select_interests")) }
    }
}
