//
//  SettingsPlaceholderView.swift
//  mkrs-world
//
//  Placeholder settings screen used across multiple tabs
//

import SwiftUI

struct SettingsPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.xxl) {
                Image(systemName: "gearshape")
                    .font(.system(size: 48))
                    .foregroundColor(.appSecondary)

                Text("Settings")
                    .font(.heading2)
                    .foregroundColor(.appPrimary)

                Text("Coming soon")
                    .font(.body14)
                    .foregroundColor(.appSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.appPrimary)
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
    }
}
