//
//  WelcomeView.swift
//  mkrs-world
//
//  Welcome screen with auth options
//

import SwiftUI
import Clerk
import AuthenticationServices

struct WelcomeView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var showEmailInput = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // Logo + Brand
                    VStack(spacing: 0) {
                        Image(.juntoLogo)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 162, height: 162)
                            .foregroundColor(.appPrimary)

                        Text("Junto")
                            .font(.juntoDisplay)
                            .foregroundColor(.appPrimary)
                    }

                    Spacer()

                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .font(.body14)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.xxl)
                            .padding(.bottom, Spacing.md)
                    }

                    // Auth Buttons
                    VStack(spacing: Spacing.md) {
                                                PrimaryButton(
                            title: "Continue with Apple",
                            icon: Image(.appleIcon),
                            isLoading: isLoading
                        ) {
                            signInWithApple()
                        }

                        PrimaryButton(
                            title: "Continue with Google",
                            icon: Image(.googleIcon),
                            variant: .outlined,
                            isLoading: isLoading
                        ) {
                            signInWithGoogle()
                        }

                        // Email Sign In
                        PrimaryButton(
                            title: "Continue with Email",
                            icon: Image(.emailIcon),
                            variant: .outlined
                        ) {
                            AnalyticsService.shared.track(.authStarted(method: .email))
                            showEmailInput = true
                        }
                    }
                    .padding(.horizontal, Spacing.xxl)
                    .padding(.bottom, Spacing.jumbo)
                }

                // Loading overlay
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showEmailInput) {
                EmailInputView(viewModel: viewModel)
            }
        }
    }

    // MARK: - Google Sign In

    private func signInWithGoogle() {
        isLoading = true
        errorMessage = nil
        AnalyticsService.shared.track(.authStarted(method: .google))

        Task {
            do {
                try await SignIn.authenticateWithRedirect(
                    strategy: .oauth(provider: .google)
                )
                AnalyticsService.shared.track(.authCompleted(method: .google))
            } catch let error as NSError where error.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                // User cancelled — do nothing
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    // MARK: - Apple Sign In

    private func signInWithApple() {
        isLoading = true
        errorMessage = nil
        AnalyticsService.shared.track(.authStarted(method: .apple))

        Task {
            do {
                let credential = try await SignInWithAppleHelper.getAppleIdCredential()
                guard let tokenData = credential.identityToken,
                      let idToken = String(data: tokenData, encoding: .utf8) else {
                    errorMessage = "Failed to get Apple ID credentials"
                    isLoading = false
                    return
                }

                let firstName = credential.fullName?.givenName
                let lastName = credential.fullName?.familyName

                // Try sign-in first (existing user), fall back to sign-up (new user)
                do {
                    try await SignIn.authenticateWithIdToken(
                        provider: .apple,
                        idToken: idToken
                    )
                } catch {
                    // User doesn't exist yet — sign up with name
                    try await SignUp.authenticateWithIdToken(
                        provider: .apple,
                        idToken: idToken,
                        firstName: firstName,
                        lastName: lastName
                    )
                }
                AnalyticsService.shared.track(.authCompleted(method: .apple))
            } catch let error as ASAuthorizationError where error.code == .canceled {
                // User cancelled — do nothing
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    WelcomeView()
}
