//
//  SectionHeader.swift
//  mkrs-world
//
//  Section title with optional disclosure chevron. Shared by Discover and
//  Messages (and any list screen with titled sections).
//

import SwiftUI

/// Section title (SF Pro semibold 20) with an optional disclosure chevron.
struct SectionHeader: View {
    let title: String
    var showsChevron: Bool = false
    var onTap: (() -> Void)? = nil

    var body: some View {
        Group {
            if let onTap {
                Button(action: onTap) { label }
                    .buttonStyle(.plain)
            } else {
                // No action → render plain so the title keeps full color
                // (a disabled Button would dim it relative to the others).
                label
            }
        }
        .padding(.horizontal, Spacing.lg)
    }

    private var label: some View {
        HStack(spacing: Spacing.xxs) {
            Text(title)
                .font(.heading2)
                .foregroundColor(.appPrimary)

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.appSecondary)
            }

            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
    }
}
