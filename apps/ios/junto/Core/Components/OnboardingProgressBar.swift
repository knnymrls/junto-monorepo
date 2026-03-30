//
//  OnboardingProgressBar.swift
//  junto
//
//  Step progress bar for onboarding — back arrow + capsule segments
//
//  Three states: answered (#333), active (#D9), unselected (#F2)
//  Active segment is 40px fixed, others flex evenly
//

import SwiftUI

struct OnboardingProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    var onBack: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: Spacing.lg) {
            // Always reserve space for back button so bar doesn't shift
            Button(action: { onBack?() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.appPrimary)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .opacity(onBack != nil ? 1 : 0)
            .disabled(onBack == nil)

            HStack(spacing: Spacing.xxs) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Capsule()
                        .fill(colorForStep(index))
                        .frame(
                            width: index == currentStep ? 40 : nil,
                            height: 4
                        )
                        .frame(maxWidth: index == currentStep ? nil : .infinity)
                }
            }
        }
        .padding(.horizontal, Spacing.xxl)
        .animation(.easeInOut(duration: 0.25), value: currentStep)
    }

    private func colorForStep(_ index: Int) -> Color {
        if index < currentStep {
            return .appAccent              // answered — #333
        } else if index == currentStep {
            return .appSecondary           // active — #999
        } else {
            return .appInputFill           // unselected — #F2F2F2
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        OnboardingProgressBar(currentStep: 0, totalSteps: 10)
        OnboardingProgressBar(currentStep: 1, totalSteps: 10) {}
        OnboardingProgressBar(currentStep: 5, totalSteps: 10) {}
        OnboardingProgressBar(currentStep: 9, totalSteps: 10) {}
    }
}
