//
//  OnboardingView.swift
//  junto
//
//  Onboarding flow shell — routes between step views
//

import SwiftUI
import Clerk

struct OnboardingView: View {
    @Environment(\.clerk) private var clerk
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var showSignOutAlert = false

    var body: some View {
        ZStack {
            // Background — transitions to gradient for final two steps
            if viewModel.step >= 8 {
                RadialGradient(
                    colors: [
                        Color(red: 50/255, green: 255/255, blue: 153/255),
                        Color(red: 50/255, green: 211/255, blue: 204/255),
                        Color(red: 50/255, green: 166/255, blue: 255/255),
                        Color(red: 136/255, green: 159/255, blue: 255/255),
                        Color(red: 222/255, green: 152/255, blue: 255/255),
                    ],
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: 600
                )
                .ignoresSafeArea()
                .transition(.opacity)
            } else {
                Color.appBackground.ignoresSafeArea()
            }

            VStack(spacing: 0) {
                if viewModel.step < viewModel.totalSteps - 2 {
                    OnboardingProgressBar(
                        currentStep: viewModel.step,
                        totalSteps: viewModel.totalSteps,
                        onBack: viewModel.step == 0
                            ? { showSignOutAlert = true }
                            : { viewModel.goBack() }
                    )
                    .padding(.top, Spacing.xl)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Group {
                    switch viewModel.step {
                    case 0: SelectCampusView(viewModel: viewModel)
                    case 1: ProfileSetupView(viewModel: viewModel)
                    case 2: SelectMajorsView(viewModel: viewModel)
                    case 3: GradYearView(viewModel: viewModel)
                    case 4: SelectProgramsView(viewModel: viewModel)
                    case 5: SelectSkillsView(viewModel: viewModel)
                    case 6: SelectInterestsView(viewModel: viewModel)
                    case 7: LookingForView(viewModel: viewModel)
                    case 8: SuggestedConnectionsView(viewModel: viewModel)
                    case 9: OnboardingWelcomeView(viewModel: viewModel)
                    default: Spacer()
                    }
                }
                .id(viewModel.step)
                .transition(.asymmetric(
                    insertion: .move(edge: viewModel.navigatingForward ? .trailing : .leading)
                        .combined(with: .opacity),
                    removal: .move(edge: viewModel.navigatingForward ? .leading : .trailing)
                        .combined(with: .opacity)
                ))
            }
            .animation(.easeInOut(duration: 0.35), value: viewModel.step)
        }
        .onAppear {
            if viewModel.step == 0 {
                AnalyticsService.shared.track(.onboardingStarted)
            }
        }
        .alert("Sign out?", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                viewModel.reset()
                Task { try? await clerk.signOut() }
            }
        } message: {
            Text("You'll need to sign in again to continue.")
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    OnboardingView()
}
