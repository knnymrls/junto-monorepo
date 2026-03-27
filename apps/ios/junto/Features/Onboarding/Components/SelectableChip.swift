//
//  SelectableChip.swift
//  junto
//
//  Toggleable chip with + / x icon — used for skills, interests, and programs
//

import SwiftUI

struct SelectableChip: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Text(title)
                .font(.bodyLargeMedium)
                .foregroundColor(isSelected ? .appOnAccent : .appPrimary)

            Image(systemName: isSelected ? "xmark" : "plus")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isSelected ? .appOnAccent : .appPrimary)
                .rotationEffect(.degrees(isSelected ? 0 : -45))
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.sm)
        .background(isSelected ? Color.appAccent : Color.appInputFill)
        .clipShape(RoundedRectangle(cornerRadius: Radius.xxl))
        .scaleEffect(isSelected ? 1.03 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isSelected)
    }
}
