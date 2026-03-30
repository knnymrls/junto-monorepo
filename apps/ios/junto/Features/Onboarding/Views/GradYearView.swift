//
//  GradYearView.swift
//  junto
//
//  Onboarding step 3: select expected graduation semester
//

import SwiftUI

struct GradYearView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Title
            Text("Class of...")
                .font(.juntoHeading)
                .foregroundColor(.appPrimary)
                .padding(.horizontal, Spacing.xxl)

            Spacer()
                .frame(height: Spacing.jumbo)

            // Semester picker
            SemesterWheelPicker(
                selection: $viewModel.gradSemester,
                options: viewModel.semesterOptions
            )
            .padding(.horizontal, Spacing.xxl)

            Spacer()

            // Continue
            PrimaryButton(
                title: "Continue",
                isEnabled: !viewModel.gradSemester.isEmpty
            ) {
                viewModel.advance()
            }
            .padding(.horizontal, Spacing.xxl)
            .padding(.bottom, Spacing.lg)
        }
        .onAppear { AnalyticsService.shared.track(.onboardingStepViewed(step: 3, stepName: "grad_year")) }
    }
}
