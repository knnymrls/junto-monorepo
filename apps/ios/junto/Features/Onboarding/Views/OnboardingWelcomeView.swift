//
//  OnboardingWelcomeView.swift
//  junto
//
//  Onboarding step 9: Welcome to Junto — final screen
//

import SwiftUI

struct OnboardingWelcomeView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    @State private var bubblesAppeared = false
    @State private var textAppeared = false
    @State private var titleAppeared = false
    @State private var buttonAppeared = false
    @State private var isFloating = false

    // Bubble configs matched to Figma: (x%, y%, size, rotation)
    // Laid out to frame the center text without overlapping
    private let bubbles: [(CGFloat, CGFloat, CGFloat, Double)] = [
        (0.49, 0.19, 90, -2),   // top center — large, hero
        (0.16, 0.30, 48, -2),   // upper left
        (0.84, 0.33, 49, 8),    // upper right
        (0.08, 0.43, 30, 4),    // far left — small
        (0.14, 0.64, 52, 9),    // lower left
        (0.87, 0.62, 42, 0),    // lower right
        (0.56, 0.72, 35, -4),   // lower center
    ]

    // Fallback initials colors for bubbles without avatars
    private let fallbackColors: [Color] = [
        .blue, .purple, .orange, .pink, .teal, .indigo, .mint
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Floating avatar bubbles
                ForEach(Array(bubbles.enumerated()), id: \.offset) { index, config in
                    let (xPct, yPct, size, rotation) = config
                    let avatar = viewModel.avatarForBubbleIndex(index)

                    FloatingBubble(
                        avatarUrl: avatar.url,
                        initials: avatar.initials,
                        fallbackColor: fallbackColors[index % fallbackColors.count],
                        size: size
                    )
                    .rotationEffect(.degrees(rotation))
                    .position(
                        x: geo.size.width * xPct,
                        y: geo.size.height * yPct
                    )
                    .scaleEffect(bubblesAppeared ? 1 : 0)
                    .opacity(bubblesAppeared ? 1 : 0)
                    .offset(y: isFloating ? -6 : 6)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.7)
                            .delay(Double(index) * 0.08),
                        value: bubblesAppeared
                    )
                    .animation(
                        .easeInOut(duration: Double.random(in: 2.5...3.5))
                            .repeatForever(autoreverses: true)
                            .delay(Double.random(in: 0...1)),
                        value: isFloating
                    )
                }

                // Center content
                VStack(spacing: Spacing.md) {
                    Spacer()

                    VStack(spacing: Spacing.xs) {
                        Text("Welcome to")
                            .font(.juntoHeading)
                            .foregroundColor(.white)
                            .opacity(textAppeared ? 1 : 0)
                            .offset(y: textAppeared ? 0 : 10)
                            .animation(.easeOut(duration: 0.4).delay(0.3), value: textAppeared)

                        Text("Junto")
                            .font(.juntoDisplay)
                            .foregroundColor(.white)
                            .scaleEffect(titleAppeared ? 1 : 0.5)
                            .opacity(titleAppeared ? 1 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5), value: titleAppeared)
                    }

                    Spacer()

                    PrimaryButton(title: "Join Junto", isEnabled: true) {
                        Task { await viewModel.completeOnboarding() }
                    }
                    .padding(.horizontal, Spacing.xxl)
                    .padding(.bottom, Spacing.lg)
                    .opacity(buttonAppeared ? 1 : 0)
                    .offset(y: buttonAppeared ? 0 : 20)
                    .animation(.easeOut(duration: 0.4).delay(0.7), value: buttonAppeared)
                }
            }
        }
        .onAppear {
            AnalyticsService.shared.track(.onboardingStepViewed(step: 9, stepName: "welcome"))
            bubblesAppeared = true
            textAppeared = true
            titleAppeared = true
            buttonAppeared = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                isFloating = true
            }
        }
    }
}

// MARK: - Floating Bubble

private struct FloatingBubble: View {
    let avatarUrl: String?
    let initials: String
    let fallbackColor: Color
    let size: CGFloat

    var body: some View {
        Group {
            if let url = avatarUrl, let imageUrl = URL(string: url) {
                AsyncImage(url: imageUrl) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    initialsView
                }
            } else {
                initialsView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white, lineWidth: 3))
    }

    private var initialsView: some View {
        ZStack {
            Circle().fill(fallbackColor.opacity(0.7))
            Text(initials)
                .font(.system(size: size * 0.35, weight: .bold))
                .foregroundColor(.white)
        }
    }
}
