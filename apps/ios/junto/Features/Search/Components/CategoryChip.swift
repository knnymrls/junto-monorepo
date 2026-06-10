//
//  CategoryChip.swift
//  junto
//
//  A "Browse By Category" chip — a colored Streamline icon + label on a
//  bordered surface. The icon color is the category's brand accent
//  (see SkillCategory), so the row reads as a coherent set of distinct
//  categories. Matches the Discover artboard's category chips (Paper 7IL-0).
//

import SwiftUI

struct CategoryChip: View {
    let category: SkillCategory
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: Spacing.xxs) {
                Image(category.icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(category.color)

                Text(category.label)
                    .font(.bodyMedium)
                    .foregroundColor(.appPrimary)
                    .lineLimit(1)
                    .fixedSize()
            }
            .padding(Spacing.sm)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.xl)
                    // True 1px hairline border (matches the app's 1px convention).
                    .strokeBorder(Color.appBorder, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: Radius.xl))
        }
        .buttonStyle(.pressableScale(0.96))
    }
}

#Preview {
    ScrollView(.horizontal, showsIndicators: false) {
        LazyHGrid(rows: [GridItem(.fixed(36)), GridItem(.fixed(36))], spacing: Spacing.sm) {
            ForEach(SkillCategory.allCases, id: \.self) { category in
                CategoryChip(category: category)
            }
        }
        .padding()
    }
    .background(Color.appBackground)
}
