//
//  LookingForView.swift
//  junto
//
//  Onboarding step 9: Need help finding...
//

import SwiftUI

struct LookingForView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: Spacing.jumbo) {
                Text("Need help finding...")
                    .font(.juntoHeading)
                    .foregroundColor(.appPrimary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                FlowLayout(spacing: Spacing.sm, centered: true) {
                    ForEach(OnboardingViewModel.lookingForOptions, id: \.self) { option in
                        Button {
                            viewModel.toggleLookingFor(option)
                        } label: {
                            SelectableChip(
                                title: option,
                                isSelected: viewModel.selectedLookingFor.contains(option)
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.xxl)

            Spacer()

            PrimaryButton(
                title: "Continue",
                isEnabled: !viewModel.selectedLookingFor.isEmpty
            ) {
                viewModel.advance()
            }
            .padding(.horizontal, Spacing.xxl)
            .padding(.bottom, Spacing.lg)
        }
        .onAppear { AnalyticsService.shared.track(.onboardingStepViewed(step: 9, stepName: "looking_for")) }
    }
}
