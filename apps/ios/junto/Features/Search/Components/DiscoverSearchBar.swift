//
//  DiscoverSearchBar.swift
//  mkrs-world
//
//  Search composer for the Discover tab. Matches Figma 160:249 — white
//  pill, no shadow, grey arrow-up send button. Submit fires only when the
//  user taps the send button or hits return; no live AI submit on every
//  keystroke (the masonry above already filters via the name/vector tiers).
//

import SwiftUI

struct DiscoverSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search for a co-founder..."
    var onSubmit: () -> Void

    private var isEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Slightly darker than `appSurface` so the pill is visible against
    /// both the white page bg and the #F2F2F2 masonry container.
    private let barFill = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1.0)
            : UIColor(red: 0.91, green: 0.91, blue: 0.91, alpha: 1.0)  // ~#E8E8E8
    })

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.body14)
                        .foregroundStyle(Color.appSecondary)
                        .allowsHitTesting(false)
                }
                TextField("", text: $text)
                    .font(.body14)
                    .foregroundStyle(Color.appPrimary)
                    .tint(Color.appPrimary)
                    .textFieldStyle(.plain)
                    .submitLabel(.search)
                    .onSubmit(onSubmit)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onSubmit) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(width: 28, height: 28)
                    .background(
                        isEmpty ? Color.appSecondary : Color.appPrimary,
                        in: RoundedRectangle(cornerRadius: Radius.xl)
                    )
            }
            .buttonStyle(.plain)
            .disabled(isEmpty)
            .animation(.easeOut(duration: 0.15), value: isEmpty)
        }
        .padding(.leading, Spacing.lg)
        .padding(.trailing, Spacing.md)
        .padding(.vertical, Spacing.md)
        .modifier(WhiteGlassBackground())
    }
}

/// Solid white pill with iOS 26 liquid-glass on top — gives a clean white
/// surface that still feels alive. Falls back to plain white on iOS 17–25.
private struct WhiteGlassBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .background(Color.appSurface, in: RoundedRectangle(cornerRadius: Radius.xxl))
                .glassEffect(.regular.tint(Color.appSurface.opacity(0.6)), in: RoundedRectangle(cornerRadius: Radius.xxl))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.xxl)
                        .stroke(Color.appBorder, lineWidth: 0.5)
                )
        } else {
            content
                .background(Color.appSurface, in: RoundedRectangle(cornerRadius: Radius.xxl))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.xxl)
                        .stroke(Color.appBorder, lineWidth: 0.5)
                )
        }
    }
}

// MARK: - Glass Background

private struct GlassBarBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .juntoGlassBackground(cornerRadius: Radius.xxl)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.xxl)
                    .stroke(Color.appBorder, lineWidth: 0.5)
            )
    }
}

// MARK: - Shared Glass Modifier

/// Junto's standard liquid-glass treatment. Uses iOS 26's `glassEffect`
/// with a surface-color tint when available; falls back to thick material
/// on iOS 17–25. Reads as a near-white pill against the grey discover
/// container — readable from black text without going dark.
struct JuntoGlassBackground: ViewModifier {
    var cornerRadius: CGFloat = Radius.xxl

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular.tint(Color.appSurface), in: RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            content
                .background(.thickMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
        }
    }
}

extension View {
    func juntoGlassBackground(cornerRadius: CGFloat = Radius.xxl) -> some View {
        modifier(JuntoGlassBackground(cornerRadius: cornerRadius))
    }
}

/// Tinted liquid-glass background for the submit button so it picks up the
/// primary action color while still feeling layered and translucent.
private struct GlassSubmitButton: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular.tint(Color.appPrimary), in: RoundedRectangle(cornerRadius: Radius.xl))
        } else {
            content
                .background(.thickMaterial, in: RoundedRectangle(cornerRadius: Radius.xl))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.xl)
                        .fill(Color.appPrimary.opacity(0.85))
                )
                .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
        }
    }
}

#Preview {
    VStack {
        Spacer()
        DiscoverSearchBar(text: .constant(""), onSubmit: {})
            .padding(.horizontal, Spacing.md)
        DiscoverSearchBar(text: .constant("Looking for an iOS dev"), onSubmit: {})
            .padding(.horizontal, Spacing.md)
        Spacer()
    }
    .background(Color.appSurfaceSecondary)
}
