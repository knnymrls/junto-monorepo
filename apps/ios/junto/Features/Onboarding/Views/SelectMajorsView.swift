//
//  SelectMajorsView.swift
//  junto
//
//  Onboarding step 4: search and select your majors (multi-select)
//

import SwiftUI

struct SelectMajorsView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Title
            Text("What are your majors?")
                .font(.juntoHeading)
                .foregroundColor(.appPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.xxl)
                .padding(.top, Spacing.jumbo)

            // Search field
            JuntoTextField(
                placeholder: "Search for your major",
                text: $viewModel.majorSearch,
                icon: Image(systemName: "magnifyingglass")
            )
            .padding(.horizontal, Spacing.xxl)
            .padding(.top, Spacing.lg)

            // Results list with fade overlays
            ZStack {
                ScrollView {
                    LazyVStack(spacing: Spacing.xxs) {
                        ForEach(Array(viewModel.majorResults.enumerated()), id: \.element.id) { index, major in
                            Button {
                                viewModel.toggleMajor(major)
                            } label: {
                                CheckboxRow(
                                    title: major.displayName,
                                    isSelected: viewModel.selectedMajorIds.contains(major.id),
                                    isFirst: index == 0,
                                    isLast: index == viewModel.majorResults.count - 1
                                )
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: Radius.xxl))
                    .padding(.horizontal, Spacing.xxl)
                    .padding(.top, Spacing.lg)
                    .padding(.bottom, Spacing.huge)
                }
                .scrollIndicators(.hidden)

                // Top + bottom fade overlays
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

            // Error
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.body14)
                    .foregroundColor(.appError)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xxl)
                    .padding(.bottom, Spacing.md)
            }

            // Continue
            PrimaryButton(
                title: "Continue",
                isEnabled: !viewModel.selectedMajorIds.isEmpty
            ) {
                viewModel.advance()
            }
            .padding(.horizontal, Spacing.xxl)
            .padding(.bottom, Spacing.lg)
        }
        .onChange(of: viewModel.majorSearch) { _, query in
            viewModel.searchMajors(query)
        }
        .task { await viewModel.loadMajors() }
        .onAppear { AnalyticsService.shared.track(.onboardingStepViewed(step: 4, stepName: "select_majors")) }
    }
}
