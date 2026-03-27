//
//  CheckboxRow.swift
//  junto
//
//  Selectable row with checkbox — used for majors, interests, etc.
//

import SwiftUI

struct CheckboxRow: View {
    let title: String
    let isSelected: Bool
    var isFirst: Bool = false
    var isLast: Bool = false

    private var shape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: isFirst ? Radius.xxl : Radius.xs,
            bottomLeadingRadius: isLast ? Radius.xxl : Radius.xs,
            bottomTrailingRadius: isLast ? Radius.xxl : Radius.xs,
            topTrailingRadius: isFirst ? Radius.xxl : Radius.xs
        )
    }

    var body: some View {
        HStack(spacing: Spacing.lg) {
            Text(title)
                .font(.bodyLargeSemibold)
                .foregroundColor(.appPrimary)
                .lineLimit(1)

            Spacer()

            Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                .font(.system(size: 16))
                .foregroundColor(isSelected ? .appAccent : .appSecondary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.lg)
        .background(isSelected ? Color.appAccent.opacity(0.2) : Color.appInputFill)
        .overlay(shape.stroke(isSelected ? Color.appAccent : Color.clear, lineWidth: 2))
        .clipShape(shape)
        .contentShape(Rectangle())
    }
}
