//
//  SchoolEmailView.swift
//  junto
//
//  Onboarding step 1: enter .edu email
//

import SwiftUI

struct SchoolEmailView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: Spacing.jumbo) {
                Text("What's your school email?")
                    .font(.juntoHeading)
                    .foregroundColor(.appPrimary)

                TextField(
                    "",
                    text: $viewModel.eduEmail,
                    prompt: Text(verbatim: "you@university.edu")
                        .foregroundStyle(Color.appSecondary)
                        .font(.bodyLargeSemibold)
                )
                .font(.bodyLargeSemibold)
                .foregroundStyle(Color.appPrimary)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .multilineTextAlignment(.center)
                .focused($isFocused)
                .tint(.appPrimary)
                .padding(.horizontal, Spacing.lg)
                .frame(height: 53)
                .frame(width: 293)
                .background(
                    RoundedRectangle(cornerRadius: Radius.xxl)
                        .fill(Color.appInputFill)
                )
            }

            Spacer()

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
                isLoading: viewModel.isVerifyingEdu,
                isEnabled: viewModel.isValidEduEmail
            ) {
                Task { await viewModel.sendEduCode() }
            }
            .padding(.horizontal, Spacing.xxl)
            .padding(.bottom, Spacing.lg)
        }
        .onAppear {
            isFocused = true
            viewModel.errorMessage = nil
            AnalyticsService.shared.track(.onboardingStepViewed(step: 1, stepName: "school_email"))
        }
    }
}
