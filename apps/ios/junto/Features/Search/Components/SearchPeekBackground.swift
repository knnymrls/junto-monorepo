//
//  SearchPeekBackground.swift
//  mkrs-world
//
//  Animated gradient background for search idle state
//

import SwiftUI

struct SearchPeekBackground: View {
    @State private var animationPhase = false

    var body: some View {
        ZStack {
            // Animated gradient
            LinearGradient(
                colors: animationPhase
                    ? [Color.appBackground, Color.appSurfaceSecondary, Color.appSurface]
                    : [Color.appSurface, Color.appBackground, Color.appSurfaceSecondary],
                startPoint: animationPhase ? .topLeading : .bottomTrailing,
                endPoint: animationPhase ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()

            // Subtle overlay
            Rectangle()
                .fill(.ultraThinMaterial)

            // Bottom gradient fade
            VStack {
                Spacer()
                LinearGradient(
                    colors: [Color.appBackground.opacity(0), Color.appBackground],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 200)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 6.0).repeatForever(autoreverses: true)) {
                animationPhase = true
            }
        }
    }
}
