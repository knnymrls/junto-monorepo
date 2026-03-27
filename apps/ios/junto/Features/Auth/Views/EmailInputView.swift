//
//  EmailInputView.swift
//  mkrs-world
//
//  Email entry screen for OTP auth flow
//

import SwiftUI

struct EmailInputView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isEmailFocused: Bool

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
                    Text("What's your email?")
                        .font(.juntoHeading)
                        .foregroundColor(.appPrimary)

                    TextField(
                        "",
                        text: $viewModel.email,
                        prompt: Text(verbatim: "you@example.com")
                            .foregroundStyle(Color.appSecondary)
                            .font(.bodyLargeSemibold)
                    )
                    .font(.bodyLargeSemibold)
                    .foregroundStyle(Color.appPrimary)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.center)
                    .focused($isEmailFocused)
                    .tint(.appPrimary)
                    .padding(.horizontal, Spacing.lg)
                    .frame(height: 53)
                    .frame(width: 293)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.xl)
                            .fill(Color.appInputFill)
                    )
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
                    isEnabled: viewModel.isValidEmail
                ) {
                    Task { await viewModel.sendCode() }
                }
                .padding(.horizontal, Spacing.xxl)
                .padding(.bottom, Spacing.jumbo)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $viewModel.codeSent) {
            VerifyEmailView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.errorMessage = nil
            isEmailFocused = true
        }
    }
}

#Preview {
    NavigationStack {
        EmailInputView(viewModel: AuthViewModel())
    }
}
