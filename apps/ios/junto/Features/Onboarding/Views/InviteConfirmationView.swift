//
//  InviteConfirmationView.swift
//  junto
//
//  Onboarding step 0 (invite flow): confirms university + program from invite link
//

import SwiftUI

struct InviteConfirmationView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // University logo
            if let link = viewModel.inviteLink {
                AvatarView(
                    avatarUrl: link.universityLogoUrl,
                    name: link.universityName,
                    size: 80
                )
                .padding(.bottom, Spacing.xxl)
            }

            // Title
            VStack(spacing: Spacing.md) {
                Text("You're joining")
                    .font(.juntoHeading)
                    .foregroundColor(.appPrimary)

                Text(viewModel.inviteLink?.universityName ?? "")
                    .font(.juntoHeading)
                    .foregroundColor(.appAccent)

                if let program = viewModel.inviteLink?.program {
                    Text(program)
                        .font(.bodyLargeSemibold)
                        .foregroundColor(.appSecondary)
                        .padding(.top, Spacing.xs)
                }
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, Spacing.xxl)

            Spacer()
                .frame(height: Spacing.jumbo)

            // Subtitle
            Text("That right?")
                .font(.bodyLarge)
                .foregroundColor(.appSecondary)

            Spacer()

            // Error
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.body14)
                    .foregroundColor(.appError)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xxl)
                    .padding(.bottom, Spacing.md)
            }

            // Confirm button
            PrimaryButton(title: "Confirm", isEnabled: true) {
                viewModel.advance()
            }
            .padding(.horizontal, Spacing.xxl)
            .padding(.bottom, Spacing.lg)
        }
        .onAppear {
            AnalyticsService.shared.track(
                .onboardingStepViewed(step: 0, stepName: "invite_confirmation"),
                extraProperties: [
                    "invite_code": viewModel.inviteCode ?? "",
                    "university": viewModel.inviteLink?.universityName ?? "",
                    "program": viewModel.inviteLink?.program ?? "",
                ]
            )
        }
    }
}
