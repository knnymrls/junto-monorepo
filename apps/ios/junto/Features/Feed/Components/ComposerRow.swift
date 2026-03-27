//
//  ComposerRow.swift
//  mkrs-world
//
//  Composer row at the top of the feed
//

import SwiftUI

struct ComposerRow: View {
    let avatarUrl: String?
    let name: String
    let onTap: () -> Void

    @State private var currentPromptIndex = 0
    @State private var promptOpacity: Double = 1
    @State private var rotationTimer: Timer?

    private let prompts = [
        "What are you working on?",
        "Share an update",
        "What are you looking for?",
        "Ask the community"
    ]

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                AvatarView(
                    avatarUrl: avatarUrl,
                    name: name,
                    size: 44
                )

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(name)
                        .font(.bodyMedium)
                        .foregroundColor(.appPrimary)

                    Text(prompts[currentPromptIndex])
                        .font(.body14)
                        .foregroundColor(.appSecondary)
                        .opacity(promptOpacity)
                }
                .frame(height: 40, alignment: .leading)

                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.lg)
            .background(Color.appSurface)
        }
        .buttonStyle(.plain)
        .onAppear {
            rotationTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    promptOpacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    currentPromptIndex = (currentPromptIndex + 1) % prompts.count
                    withAnimation(.easeIn(duration: 0.3)) {
                        promptOpacity = 1
                    }
                }
            }
        }
        .onDisappear {
            rotationTimer?.invalidate()
            rotationTimer = nil
        }
    }
}
