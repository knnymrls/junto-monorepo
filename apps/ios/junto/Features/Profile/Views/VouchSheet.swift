//
//  VouchSheet.swift
//  mkrs-world
//
//  Sheet for writing a vouch reason and submitting
//

import SwiftUI

struct VouchSheet: View {
    let userName: String
    let fromUserId: String
    let toUserId: String
    var onVouched: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var reason = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @FocusState private var isFocused: Bool

    private var trimmedReason: String { reason.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var isValid: Bool { trimmedReason.count >= 10 }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Text("What makes \(userName) great to work with?")
                        .font(.bodyLargeMedium)
                        .foregroundColor(.appPrimary)
                        .padding(.top, Spacing.lg)

                    JuntoTextArea(
                        placeholder: "e.g. Built the entire matching algorithm from scratch",
                        text: $reason,
                        characterLimit: 200
                    )
                    .focused($isFocused)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.bodySmall)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, Spacing.lg)

                Spacer()

                // Submit button
                Button(action: { submit() }) {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    } else {
                        Text("Vouch for \(userName)")
                            .font(.bodyLargeSemibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                }
                .background(isValid ? Color.appPrimary : Color.appSecondary)
                .cornerRadius(Radius.xl)
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.lg)
                .disabled(!isValid || isSubmitting)
            }
            .background(Color.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.appSecondary)
                }

                ToolbarItem(placement: .principal) {
                    Text("Vouch")
                        .font(.bodyLargeSemibold)
                        .foregroundColor(.appPrimary)
                }
            }
        }
        .presentationDragIndicator(.visible)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
            }
        }
    }

    private func submit() {
        isSubmitting = true
        errorMessage = nil
        Task {
            do {
                _ = try await ConvexClientManager.shared.createVouch(
                    fromUserId: fromUserId,
                    toUserId: toUserId,
                    reason: trimmedReason
                )
                onVouched()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isSubmitting = false
            }
        }
    }
}
