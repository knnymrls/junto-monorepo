//
//  TopicTag.swift
//  junto
//
//  Skill-category tag (icon + label) for feed cards — the pill row on
//  Ask/Match cards. Matches Figma nodes 70:1645 / 70:1733.
//
//  Both post topics and match-card tags draw from the same skill-category
//  vocabulary, so a single category → icon map covers every feed card
//  (see backend convex/topics.ts:listSkillCategories).
//

import SwiftUI

struct TopicTag: View {
    let category: String

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            if let icon = TopicIcon.assetName(for: category) {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
            }

            Text(category)
                .font(.body14)
                .lineLimit(1)
        }
        .foregroundColor(.appSecondary)
    }
}

// MARK: - Category → icon map

/// Maps a skill category (post topic / match tag) to a line icon asset.
///
/// Line icons on the plain card background, per the icon convention.
/// Returns `nil` for categories that don't have a designed icon yet — the
/// tag then renders label-only rather than guessing an icon. Add cases here
/// (with a matching `topic.*` imageset) as Kenny designs them.
enum TopicIcon {
    static func assetName(for category: String) -> String? {
        switch category.lowercased() {
        case "software development", "software engineering", "engineering", "development", "programming":
            return "topic.code"
        case "design", "ui design", "ux design", "product design", "graphic design":
            return "topic.design"
        default:
            return nil
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: Spacing.md) {
        TopicTag(category: "Software Development")
        TopicTag(category: "Design")
        TopicTag(category: "Business") // no icon yet → label only
        FlowLayout(spacing: Spacing.md) {
            TopicTag(category: "Software Development")
            TopicTag(category: "Design")
        }
    }
    .padding()
    .background(Color.appBackground)
}
