//
//  CategoryPill.swift
//  mkrs-world
//
//  Colored category pill badge for posts
//

import SwiftUI

struct CategoryPill: View {
    let category: PostResponse.PostCategory

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Image(iconName)
                .resizable()
                .frame(width: 14, height: 14)

            Text(displayName)
                .font(.captionMedium)
        }
        .foregroundColor(textColor)
        .padding(.horizontal, 10)
        .frame(height: 28)
        .background(backgroundColor)
        .clipShape(Capsule())
    }

    private var iconName: String {
        switch category {
        case .sharing: return "content.sharing"
        case .lookingFor: return "content.looking"
        case .asking: return "content.asking"
        }
    }

    private var displayName: String {
        switch category {
        case .sharing: return "Sharing"
        case .lookingFor: return "Looking For"
        case .asking: return "Asking"
        }
    }

    // Adaptive text colors — lighter in dark mode for contrast
    private var textColor: Color {
        switch category {
        case .sharing:
            return Color(UIColor { $0.userInterfaceStyle == .dark
                ? UIColor(red: 1.00, green: 0.55, blue: 0.20, alpha: 1.0)  // brighter orange
                : UIColor(red: 0.90, green: 0.32, blue: 0.00, alpha: 1.0)  // #E65100
            })
        case .lookingFor:
            return Color(UIColor { $0.userInterfaceStyle == .dark
                ? UIColor(red: 0.35, green: 0.65, blue: 1.00, alpha: 1.0)  // brighter blue
                : UIColor(red: 0.08, green: 0.40, blue: 0.75, alpha: 1.0)  // #1565C0
            })
        case .asking:
            return Color(UIColor { $0.userInterfaceStyle == .dark
                ? UIColor(red: 0.73, green: 0.40, blue: 0.90, alpha: 1.0)  // brighter purple
                : UIColor(red: 0.48, green: 0.12, blue: 0.64, alpha: 1.0)  // #7B1FA2
            })
        }
    }

    // Adaptive backgrounds — dark tinted in dark mode
    private var backgroundColor: Color {
        switch category {
        case .sharing:
            return Color(UIColor { $0.userInterfaceStyle == .dark
                ? UIColor(red: 0.25, green: 0.15, blue: 0.05, alpha: 1.0)
                : UIColor(red: 1.00, green: 0.95, blue: 0.88, alpha: 1.0)  // #FFF3E0
            })
        case .lookingFor:
            return Color(UIColor { $0.userInterfaceStyle == .dark
                ? UIColor(red: 0.05, green: 0.12, blue: 0.25, alpha: 1.0)
                : UIColor(red: 0.89, green: 0.95, blue: 0.99, alpha: 1.0)  // #E3F2FD
            })
        case .asking:
            return Color(UIColor { $0.userInterfaceStyle == .dark
                ? UIColor(red: 0.18, green: 0.08, blue: 0.25, alpha: 1.0)
                : UIColor(red: 0.95, green: 0.90, blue: 0.96, alpha: 1.0)  // #F3E5F5
            })
        }
    }
}
