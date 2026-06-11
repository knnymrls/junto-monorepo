//
//  ReportPostSheet.swift
//  mkrs-world
//
//  Sheet for reporting a post
//

import SwiftUI

struct ReportPostSheet: View {
    let postId: String
    let reporterId: String

    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason: ReportReason?
    @State private var details: String = ""
    @State private var isSubmitting = false
    @State private var isSubmitted = false
    @State private var submitError: String?

    enum ReportReason: String, CaseIterable {
        case spam = "spam"
        case harassment = "harassment"
        case inappropriate = "inappropriate"
        case other = "other"

        var displayName: String {
            switch self {
            case .spam: return "Spam"
            case .harassment: return "Harassment"
            case .inappropriate: return "Inappropriate Content"
            case .other: return "Other"
            }
        }

        var icon: String {
            switch self {
            case .spam: return "envelope.badge"
            case .harassment: return "hand.raised"
            case .inappropriate: return "exclamationmark.triangle"
            case .other: return "ellipsis.circle"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isSubmitted {
                    confirmationView
                } else {
                    reportFormView
                }
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
                    Text("Report Post")
                        .font(.bodyLargeSemibold)
                        .foregroundColor(.appPrimary)
                }
            }
        }
        .presentationDragIndicator(.visible)
        .errorAlert($submitError, title: "Couldn't Submit Report")
    }

    // MARK: - Report Form

    private var reportFormView: some View {
        VStack(spacing: Spacing.lg) {
            // Reason selection
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Why are you reporting this post?")
                    .font(.bodyLargeMedium)
                    .foregroundColor(.appPrimary)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.lg)

                ForEach(ReportReason.allCases, id: \.rawValue) { reason in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedReason = reason
                        }
                    }) {
                        HStack(spacing: Spacing.md) {
                            Image(systemName: reason.icon)
                                .font(.system(size: 18))
                                .foregroundColor(selectedReason == reason ? .appPrimary : .appSecondary)
                                .frame(width: 24)

                            Text(reason.displayName)
                                .font(.bodyLarge)
                                .foregroundColor(.appPrimary)

                            Spacer()

                            if selectedReason == reason {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.appPrimary)
                                    .font(.system(size: 20))
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.appSecondary)
                                    .font(.system(size: 20))
                            }
                        }
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.md)
                        .background(
                            selectedReason == reason
                                ? Color.appSurfaceSecondary
                                : Color.clear
                        )
                        .cornerRadius(Radius.lg)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, Spacing.md)
                }
            }

            // Details field (shown when "Other" is selected)
            if selectedReason == .other {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Tell us more")
                        .font(.bodyLargeMedium)
                        .foregroundColor(.appPrimary)

                    TextField("Describe the issue...", text: $details, axis: .vertical)
                        .font(.bodyLarge)
                        .foregroundColor(.appPrimary)
                        .lineLimit(3...6)
                        .padding(Spacing.md)
                        .background(Color.appSurfaceSecondary)
                        .cornerRadius(Radius.lg)
                }
                .padding(.horizontal, Spacing.lg)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Spacer()

            // Submit button
            Button(action: { submitReport() }) {
                if isSubmitting {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                } else {
                    Text("Submit Report")
                        .font(.bodyLargeSemibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
            }
            .background(selectedReason != nil ? Color.appPrimary : Color.appSecondary)
            .cornerRadius(Radius.xl)
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.lg)
            .disabled(selectedReason == nil || isSubmitting)
        }
    }

    // MARK: - Confirmation

    private var confirmationView: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(.appPrimary)

            Text("Report submitted")
                .font(.heading3Regular)
                .foregroundColor(.appPrimary)

            Text("We'll review it shortly.")
                .font(.bodyLarge)
                .foregroundColor(.appSecondary)

            Spacer()

            Button(action: { dismiss() }) {
                Text("Done")
                    .font(.bodyLargeSemibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .background(Color.appPrimary)
            .cornerRadius(Radius.xl)
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.lg)
        }
    }

    // MARK: - Submit

    private func submitReport() {
        guard let reason = selectedReason else { return }
        isSubmitting = true

        Task {
            do {
                _ = try await ConvexClientManager.shared.reportPost(
                    reporterId: reporterId,
                    postId: postId,
                    reason: reason.rawValue,
                    details: reason == .other ? details : nil
                )

                isSubmitting = false
                withAnimation {
                    isSubmitted = true
                }
            } catch {
                print("ReportPostSheet: Failed to submit report: \(error)")
                submitError = "Couldn't submit your report. Check your connection and try again."
                isSubmitting = false
            }
        }
    }
}
