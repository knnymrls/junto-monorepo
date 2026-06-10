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
    /// Explicit icon source — used when the label itself isn't a category
    /// (e.g. an event type like "Pitch" borrowing its event's primary category).
    var iconCategory: SkillCategory? = nil

    private var iconAsset: String? {
        (iconCategory ?? SkillCategory.match(category))?.icon
    }

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            if let icon = iconAsset {
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
/// Delegates to the canonical `SkillCategory` taxonomy so every feed tag,
/// event-card category, and Discover chip shares one icon vocabulary. Returns
/// `nil` for strings that don't normalize to a known category — the tag then
/// renders label-only rather than guessing an icon.
enum TopicIcon {
    static func assetName(for category: String) -> String? {
        SkillCategory.match(category)?.icon
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
