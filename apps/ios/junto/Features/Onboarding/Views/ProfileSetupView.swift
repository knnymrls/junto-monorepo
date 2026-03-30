//
//  ProfileSetupView.swift
//  junto
//
//  Onboarding step 1: set up profile photo, name, and headline
//

import SwiftUI

struct ProfileSetupView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: Spacing.jumbo) {
                    // Photo picker
                    ProfilePhotoPicker(image: $viewModel.profileImage)
                        .padding(.top, Spacing.jumbo)

                    // Title
                    VStack(spacing: Spacing.sm) {
                        Text("Your Profile")
                            .font(.juntoHeading)
                            .foregroundColor(.appPrimary)

                        Text("This is how you will appear on the app")
                            .font(.bodyLarge)
                            .foregroundColor(.appSecondary)
                    }

                    // Fields
                    VStack(spacing: Spacing.xl) {
                        JuntoTextField(
                            placeholder: "Your name",
                            text: $viewModel.displayName,
                            label: "Name",
                            textContentType: .name,
                            autocapitalization: .words
                        )

                        JuntoTextArea(
                            placeholder: "Introduce yourself as you would at a party, keep it short",
                            text: $viewModel.headline,
                            label: "Headline",
                            characterLimit: 50
                        )
                    }
                    .padding(.horizontal, Spacing.xxl)
                }
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.body14)
                    .foregroundColor(.appError)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xxl)
                    .padding(.bottom, Spacing.md)
            }

            PrimaryButton(
                title: "Continue",
                isEnabled: !viewModel.displayName.trimmingCharacters(in: .whitespaces).isEmpty
            ) {
                viewModel.advance()
            }
            .padding(.horizontal, Spacing.xxl)
            .padding(.bottom, Spacing.lg)
        }
        .onAppear {
            viewModel.errorMessage = nil
            AnalyticsService.shared.track(.onboardingStepViewed(step: 1, stepName: "profile_setup"))
        }
    }
}
