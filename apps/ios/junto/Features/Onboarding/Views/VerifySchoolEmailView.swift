//
//  VerifySchoolEmailView.swift
//  junto
//
//  Onboarding step 2: verify .edu email with OTP code
//

import SwiftUI

struct VerifySchoolEmailView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            if viewModel.eduVerified {
                // Success state
                VStack(spacing: Spacing.lg) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.appSuccess)

                    Text("Verified!")
                        .font(.juntoHeading)
                        .foregroundColor(.appPrimary)
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                // Code entry state
                VStack(spacing: Spacing.jumbo) {
                    VStack(spacing: Spacing.md) {
                        Text("Verify your email")
                            .font(.juntoHeading)
                            .foregroundColor(.appPrimary)

                        Text("Enter the 6-digit code from your email")
                            .font(.bodyLarge)
                            .foregroundColor(.appSecondary)
                    }

                    CodeInputView(code: $viewModel.eduCode)

                    HStack(spacing: 4) {
                        Text("Didn't get anything?")
                            .foregroundColor(.appSecondary)

                        if viewModel.eduResendCooldown > 0 {
                            Text("Resend in \(viewModel.eduResendCooldown)s")
                                .fontWeight(.semibold)
                                .foregroundColor(.appSecondary)
                        } else {
                            Button("Resend") {
                                Task { await viewModel.resendEduCode() }
                            }
                            .fontWeight(.semibold)
                            .foregroundColor(.appPrimary)
                        }
                    }
                    .font(.bodyLarge)
                }
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
                isEnabled: viewModel.eduCode.count == 6
            ) {
                Task { await viewModel.verifyEduCode() }
            }
            .padding(.horizontal, Spacing.xxl)
            .padding(.bottom, Spacing.lg)
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.eduVerified)
        .onAppear { AnalyticsService.shared.track(.onboardingStepViewed(step: 2, stepName: "verify_email")) }
        .task {
            viewModel.eduCode = ""
            viewModel.errorMessage = nil
            // If app restarted on this step but email is already verified, skip ahead
            await viewModel.checkEduAlreadyVerified()
        }
        .onChange(of: viewModel.eduCode) { _, newValue in
            if newValue.count == 6 && !viewModel.isVerifyingEdu {
                Task { await viewModel.verifyEduCode() }
            }
        }
    }
}
