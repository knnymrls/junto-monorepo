//
//  FeedTypeLabel.swift
//  junto
//
//  The colored type label on a feed card header (icon + text).
//  Ask (red) · Opportunity (purple) · Match (blue) — matches Figma node 1:39.
//

import SwiftUI

struct FeedTypeLabel: View {
    enum Kind {
        case ask          // posts asking for help
        case opportunity  // events
        case match        // suggested matches
    }

    let kind: Kind

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Image(iconName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)

            Text(title)
                .font(.captionMedium)
        }
        .foregroundColor(color)
    }

    // MARK: - Per-kind config

    private var iconName: ImageResource {
        switch kind {
        case .ask:         return .feedAsk
        case .opportunity: return .feedOpportunity
        case .match:       return .feedMatch
        }
    }

    private var title: String {
        switch kind {
        case .ask:         return "Ask"
        case .opportunity: return "Opportunity"
        case .match:       return "Match"
        }
    }

    /// Brand label colors — Figma values in light, brightened for contrast in dark.
    private var color: Color {
        switch kind {
        case .ask:
            return Color(UIColor { $0.userInterfaceStyle == .dark
                ? UIColor(red: 1.00, green: 0.36, blue: 0.42, alpha: 1.0)   // brighter red
                : UIColor(red: 1.00, green: 0.00, blue: 0.137, alpha: 1.0)  // #FF0023
            })
        case .opportunity:
            return Color(UIColor { $0.userInterfaceStyle == .dark
                ? UIColor(red: 0.71, green: 0.42, blue: 0.84, alpha: 1.0)   // brighter purple
                : UIColor(red: 0.416, green: 0.106, blue: 0.604, alpha: 1.0) // #6A1B9A
            })
        case .match:
            return Color(UIColor { $0.userInterfaceStyle == .dark
                ? UIColor(red: 0.36, green: 0.55, blue: 1.00, alpha: 1.0)   // brighter blue
                : UIColor(red: 0.00, green: 0.318, blue: 1.00, alpha: 1.0)  // #0051FF
            })
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: Spacing.lg) {
        FeedTypeLabel(kind: .ask)
        FeedTypeLabel(kind: .opportunity)
        FeedTypeLabel(kind: .match)
    }
    .padding()
    .background(Color.appBackground)
}
