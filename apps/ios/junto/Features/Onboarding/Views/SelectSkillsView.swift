//
//  SelectSkillsView.swift
//  junto
//
//  Onboarding step 7: search and select skills
//

import SwiftUI

struct SelectSkillsView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Title
            Text("What are your skills?")
                .font(.juntoHeading)
                .foregroundColor(.appPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.xxl)
                .padding(.top, Spacing.jumbo)

            // Search
            JuntoTextField(
                placeholder: "Search for a skill...",
                text: $viewModel.skillSearch,
                icon: Image(systemName: "magnifyingglass")
            )
            .padding(.horizontal, Spacing.xxl)
            .padding(.top, Spacing.lg)

            // Chips
            ZStack {
                ScrollView {
                    FlowLayout(spacing: Spacing.sm, centered: true) {
                        ForEach(viewModel.skillResults) { skill in
                            Button {
                                viewModel.toggleSkill(skill)
                            } label: {
                                SelectableChip(
                                    title: skill.name,
                                    isSelected: viewModel.selectedSkillIds.contains(skill.id)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.lg)
                    .padding(.bottom, Spacing.huge)
                }
                .scrollIndicators(.hidden)

                // Gradient fades
                VStack {
                    LinearGradient(
                        colors: [Color.appBackground, Color.appBackground.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 16)

                    Spacer()

                    LinearGradient(
                        colors: [Color.appBackground.opacity(0), Color.appBackground],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 24)
                }
                .allowsHitTesting(false)
            }

            // Continue
            PrimaryButton(
                title: "Continue",
                isEnabled: !viewModel.selectedSkillIds.isEmpty
            ) {
                viewModel.advance()
            }
            .padding(.horizontal, Spacing.xxl)
            .padding(.bottom, Spacing.lg)
        }
        .onChange(of: viewModel.skillSearch) { _, query in
            viewModel.searchSkills(query)
        }
        .task { await viewModel.loadSkills() }
        .onAppear { AnalyticsService.shared.track(.onboardingStepViewed(step: 7, stepName: "select_skills")) }
    }
}
