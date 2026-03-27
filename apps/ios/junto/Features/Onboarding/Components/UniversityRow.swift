//
//  UniversityRow.swift
//  junto
//
//  University search result row — logo, name, location
//

import SwiftUI

struct UniversityRow: View {
    let university: UniversityResult
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            AvatarView(
                avatarUrl: university.logoUrl,
                name: university.name,
                size: 40
            )

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(university.name)
                    .font(.bodyLargeSemibold)
                    .foregroundColor(.appPrimary)
                    .lineLimit(1)

                Text("\(university.city), \(university.state)")
                    .font(.bodyLarge)
                    .foregroundColor(.appSecondary)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.appAccent)
                    .font(.system(size: 20))
            }
        }
        .padding(.horizontal, Spacing.xxl)
        .padding(.vertical, Spacing.md)
        .contentShape(Rectangle())
    }
}
