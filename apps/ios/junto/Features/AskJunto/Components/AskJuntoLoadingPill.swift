//
//  AskJuntoLoadingPill.swift
//  junto
//
//  The assistant's thinking state — a small left-aligned pill shown while a
//  message row's status is `.pending`. Cycles through a few "thinking" phrases
//  so the wait feels like progress rather than a single frozen label
//  (Figma 148-1093 is the base; the cycling phrases extend it).
//

import SwiftUI

struct AskJuntoLoadingPill: View {
    /// Phrases cycled while thinking. Pass a single-element array for a static
    /// label (e.g. strip placeholders).
    var phrases: [String] = [
        "Searching campus...",
        "Reading profiles...",
        "Finding the best fits...",
        "Pulling it together...",
    ]

    @State private var index = 0
    private let timer = Timer.publish(every: 1.9, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ProgressView()
                .controlSize(.small)
                .tint(.appSecondary)

            Text(phrases[safe: index] ?? phrases.first ?? "")
                .font(.bodyLarge)
                .foregroundColor(.appSecondary)
                .id(index)
                .transition(.opacity)

            TypingDots()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.appSurfaceSecondary, in: Capsule())
        .onReceive(timer) { _ in
            guard phrases.count > 1 else { return }
            withAnimation(.easeInOut(duration: 0.35)) {
                index = (index + 1) % phrases.count
            }
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    AskJuntoLoadingPill()
        .padding()
        .background(Color.appBackground)
}
