//
//  AuthViewModel.swift
//  mkrs-world
//
//  Manages email OTP auth flow state
//

import Foundation
import Clerk

@MainActor
class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var code = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var codeSent = false
    @Published var resendCooldown = 0

    private var isSignInFlow = true
    private var cooldownTimer: Timer?
    private var currentSignIn: SignIn?
    private var currentSignUp: SignUp?

    var isValidEmail: Bool {
        let parts = email.split(separator: "@")
        return parts.count == 2 && parts.last?.contains(".") == true
    }

    // MARK: - Send Code

    func sendCode() async {
        isLoading = true
        errorMessage = nil

        do {
            // Try sign-in first (existing user)
            let signIn = try await SignIn.create(strategy: .identifier(email, password: nil))
            currentSignIn = try await signIn.prepareFirstFactor(strategy: .emailCode())
            isSignInFlow = true
            codeSent = true
            startCooldown()
        } catch {
            // User doesn't exist — try sign-up
            do {
                let signUp = try await SignUp.create(
                    strategy: .standard(emailAddress: email, password: nil)
                )
                currentSignUp = try await signUp.prepareVerification(strategy: .emailCode)
                isSignInFlow = false
                codeSent = true
                startCooldown()
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }

    // MARK: - Verify Code

    func verifyCode() async {
        isLoading = true
        errorMessage = nil

        do {
            if isSignInFlow {
                guard let signIn = currentSignIn else {
                    errorMessage = "No active sign-in session"
                    isLoading = false
                    return
                }
                let result = try await signIn.attemptFirstFactor(strategy: .emailCode(code: code))
                if result.status == .complete {
                    AnalyticsService.shared.track(.authCompleted(method: .email))
                } else {
                    errorMessage = "Verification incomplete. Please try again."
                }
            } else {
                guard var signUp = currentSignUp else {
                    errorMessage = "No active sign-up session"
                    isLoading = false
                    return
                }
                signUp = try await signUp.attemptVerification(strategy: .emailCode(code: code))
                if signUp.status == .complete ||
                    (signUp.missingFields.isEmpty && signUp.unverifiedFields.isEmpty) {
                    AnalyticsService.shared.track(.authCompleted(method: .email))
                } else {
                    errorMessage = "Verification incomplete. Please try again."
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Resend Code

    func resendCode() async {
        guard resendCooldown == 0 else { return }

        isLoading = true
        errorMessage = nil
        code = ""

        do {
            if isSignInFlow, let signIn = currentSignIn {
                currentSignIn = try await signIn.prepareFirstFactor(strategy: .emailCode())
            } else if !isSignInFlow, let signUp = currentSignUp {
                currentSignUp = try await signUp.prepareVerification(strategy: .emailCode)
            }
            startCooldown()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func startCooldown() {
        resendCooldown = 30
        cooldownTimer?.invalidate()
        cooldownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self else { timer.invalidate(); return }
                self.resendCooldown -= 1
                if self.resendCooldown <= 0 {
                    self.resendCooldown = 0
                    timer.invalidate()
                }
            }
        }
    }

}
