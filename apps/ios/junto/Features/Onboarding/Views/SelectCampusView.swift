//
//  SelectCampusView.swift
//  junto
//
//  Onboarding step 0: search and select your university
//

import SwiftUI

struct SelectCampusView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Title
            Text("Select your campus")
                .font(.juntoHeading)
                .foregroundColor(.appPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.xxl)
                .padding(.top, Spacing.jumbo)

            // Search field
            JuntoTextField(
                placeholder: "Enter your campus",
                text: $viewModel.campusSearch,
                icon: Image(systemName: "magnifyingglass"),
                autocapitalization: .words
            )
            .padding(.horizontal, Spacing.xxl)
            .padding(.top, Spacing.lg)

            // Results list with top + bottom fade
            ZStack {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.campusResults) { university in
                            Button {
                                viewModel.selectUniversity(university)
                            } label: {
                                UniversityRow(
                                    university: university,
                                    isSelected: viewModel.selectedUniversity?._id == university._id
                                )
                            }

                            if university.id != viewModel.campusResults.last?.id {
                                Divider()
                                    .background(Color.appDivider)
                                    .padding(.horizontal, Spacing.xxl)
                            }
                        }
                    }
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
                isEnabled: viewModel.selectedUniversity != nil
            ) {
                viewModel.advance()
            }
            .padding(.horizontal, Spacing.xxl)
            .padding(.bottom, Spacing.lg)
        }
        .onChange(of: viewModel.campusSearch) { _, query in
            Task { await viewModel.searchCampus(query) }
        }
        .task { await viewModel.loadDefaultCampuses() }
        .onAppear { AnalyticsService.shared.track(.onboardingStepViewed(step: 0, stepName: "select_campus")) }
    }
}
