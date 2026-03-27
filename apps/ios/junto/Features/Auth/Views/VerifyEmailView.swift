//
//  VerifyEmailView.swift
//  mkrs-world
//
//  Email verification code entry screen
//

import SwiftUI

struct VerifyEmailView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Back button
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.appPrimary)
                            .frame(width: 24, height: 24)
                            .contentShape(Rectangle())
                    }
                    Spacer()
                }
                .padding(.leading, Spacing.xxl)

                Spacer()

                // Content
                VStack(spacing: Spacing.jumbo) {
                    // Header
                    VStack(spacing: Spacing.md) {
                        Text("Verify your email")
                            .font(.juntoHeading)
                            .foregroundColor(.appPrimary)

                        Text("Enter the 6-digit code from your email")
                            .font(.bodyLarge)
                            .foregroundColor(.appSecondary)
                    }

                    // Code input boxes
                    CodeInputView(code: $viewModel.code)

                    // Resend
                    HStack(spacing: 4) {
                        Text("Didn't get anything?")
                            .foregroundColor(.appSecondary)

                        if viewModel.resendCooldown > 0 {
                            Text("Resend in \(viewModel.resendCooldown)s")
                                .fontWeight(.semibold)
                                .foregroundColor(.appSecondary)
                        } else {
                            Button("Resend") {
                                Task { await viewModel.resendCode() }
                            }
                            .fontWeight(.semibold)
                            .foregroundColor(.appPrimary)
                        }
                    }
                    .font(.bodyLarge)
                }

                Spacer()

                // Error message
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.body14)
                        .foregroundColor(.appError)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xxl)
                        .padding(.bottom, Spacing.md)
                }

                // Continue button
                PrimaryButton(
                    title: "Continue",
                    isLoading: viewModel.isLoading,
                    isEnabled: viewModel.code.count == 6
                ) {
                    Task { await viewModel.verifyCode() }
                }
                .padding(.horizontal, Spacing.xxl)
                .padding(.bottom, Spacing.jumbo)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            viewModel.code = ""
            viewModel.errorMessage = nil
        }
        .onChange(of: viewModel.code) { _, newValue in
            // Auto-verify when all 6 digits entered
            if newValue.count == 6 && !viewModel.isLoading {
                Task { await viewModel.verifyCode() }
            }
        }
    }
}

#Preview {
    NavigationStack {
        VerifyEmailView(viewModel: AuthViewModel())
    }
}
