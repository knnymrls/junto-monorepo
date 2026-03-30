//
//  PrimaryButton.swift
//  junto
//
//  Full-width pill button — filled or outlined, optional leading icon
//

import SwiftUI

enum ButtonVariant {
    case filled
    case outlined
}

struct PrimaryButton: View {
    let title: String
    var icon: Image? = nil
    var variant: ButtonVariant = .filled
    var isLoading: Bool = false
    var isEnabled: Bool = true
    var action: () -> Void

    private var foreground: Color {
        if variant == .outlined { return .appPrimary }
        return isEnabled ? .appOnAccent : .appSecondary
    }

    var body: some View {
        Button {
            if isEnabled {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            action()
        } label: {
            ZStack {
                if let icon {
                    HStack {
                        icon
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        Spacer()
                    }
                }

                if isLoading {
                    ProgressView()
                        .tint(foreground)
                } else {
                    Text(title)
                        .font(.bodyLargeSemibold)
                }
            }
            .foregroundColor(foreground)
            .padding(.horizontal, Spacing.lg)
            .frame(maxWidth: .infinity)
            .frame(height: 53)
            .background(
                variant == .filled
                    ? Capsule().fill(isEnabled ? Color.appAccent : Color.appSurfaceSecondary)
                    : Capsule().fill(Color.clear)
            )
            .overlay(
                variant == .outlined
                    ? Capsule().stroke(Color.appDivider, lineWidth: 1)
                    : nil
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1.0 : 0.6)
    }
}

// MARK: - Press Scale Effect

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview("Filled") {
    PrimaryButton(title: "Continue") {}
        .padding()
}

#Preview("Outlined") {
    PrimaryButton(title: "Continue with Google", icon: Image(systemName: "g.circle.fill"), variant: .outlined) {}
        .padding()
}

#Preview("Filled with Icon") {
    PrimaryButton(title: "Continue with Apple", icon: Image(systemName: "apple.logo")) {}
        .padding()
}
