//
//  SelectProgramsView.swift
//  junto
//
//  Onboarding step 4: select programs (Raikes School, Catalyst, etc.)
//

import SwiftUI

struct SelectProgramsView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Title
            Text("Are you in any programs?")
                .font(.juntoHeading)
                .foregroundColor(.appPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xxl)

            Spacer()
                .frame(height: Spacing.jumbo)

            // Program chips
            if viewModel.availablePrograms.isEmpty {
                Text("No programs found for your university")
                    .font(.bodyLarge)
                    .foregroundColor(.appSecondary)
                    .padding(.horizontal, Spacing.xxl)
            } else {
                FlowLayout(spacing: Spacing.sm, centered: true) {
                    ForEach(viewModel.availablePrograms, id: \.self) { program in
                        Button {
                            viewModel.toggleProgram(program)
                        } label: {
                            SelectableChip(
                                title: program,
                                isSelected: viewModel.selectedPrograms.contains(program)
                            )
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
            }

            Spacer()

            // Continue (always enabled — programs are optional)
            PrimaryButton(title: "Continue", isEnabled: true) {
                viewModel.advance()
            }
            .padding(.horizontal, Spacing.xxl)
            .padding(.bottom, Spacing.lg)
        }
        .task { await viewModel.loadPrograms() }
        .onAppear { AnalyticsService.shared.track(.onboardingStepViewed(step: 4, stepName: "select_programs")) }
    }
}
