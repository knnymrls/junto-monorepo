//
//  FeedbackImprovementChip.swift
//  mkrs-world
//
//  Selectable capsule chip for feedback improvement options
//

import SwiftUI

struct FeedbackImprovementChip: View {
    let title: String
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            Text(title)
                .font(.bodyMedium)
                .foregroundColor(isSelected ? .white : .appPrimary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(isSelected ? Color.appPrimary : Color.clear)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color.appDivider, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
