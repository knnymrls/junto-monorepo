//
//  AppTheme.swift
//  junto
//
//  Centralized theme colors — adaptive light/dark mode
//
//  Naming: appPrimary/appSecondary (text), appSurface (cards),
//  appAccent (actions), appOnAccent (text on accent fills)
//

import SwiftUI

// MARK: - Semantic Color Tokens

extension Color {

    // --- Text ---

    /// Primary text — #2D2D2D light / white dark
    static let appPrimary = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? .white
            : UIColor(red: 0.176, green: 0.176, blue: 0.176, alpha: 1.0)  // #2D2D2D
    })

    /// Secondary text — #999 light / lightGray dark
    static let appSecondary = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? .lightGray
            : UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)  // #999999
    })

    /// Tertiary text — very muted
    static let appTertiary = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? .darkGray
            : UIColor.gray.withAlphaComponent(0.5)
    })

    /// Text on dark backgrounds (hero images, overlays)
    static let appSecondaryOnDark = Color.white.opacity(0.7)

    // --- Backgrounds & Surfaces ---

    /// Page background — white light / #101010 dark
    static let appBackground = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.063, green: 0.063, blue: 0.063, alpha: 1.0)  // #101010
            : .white
    })

    /// Card / elevated surface — same as background (cards use border or shadow to lift)
    static let appSurface = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.063, green: 0.063, blue: 0.063, alpha: 1.0)  // #101010
            : .white
    })

    /// Secondary surface — subtle lift from background
    static let appSurfaceSecondary = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 1.0)   // #1C1C1C
            : UIColor(red: 0.949, green: 0.949, blue: 0.949, alpha: 1.0) // #F2F2F2
    })

    /// Dimmed surface — drawer/menu areas
    static let appSurfaceDimmed = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0)
            : UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)  // #F5F5F5
    })

    /// Slide-out drawer background — pure white (light) / pure black (dark), so
    /// the rounded content page reads as a layer on top of it.
    static let appDrawerBackground = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark ? .black : .white
    })

    /// Input fill — #F2F2F2 light / #262626 dark
    static let appInputFill = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)   // #262626
            : UIColor(red: 0.949, green: 0.949, blue: 0.949, alpha: 1.0) // #F2F2F2
    })

    // --- Actions ---

    /// Accent / primary action — #333 light / white dark
    static let appAccent = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? .white
            : UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)  // #333333
    })

    /// Text on accent fills — white light / black dark
    static let appOnAccent = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? .black
            : .white
    })

    /// System tint (links, interactive highlights)
    static let appTint = Color(UIColor.systemBlue)

    // --- Borders & Dividers ---

    /// Subtle border — 5% black light / 10% white dark
    static let appBorder = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.1)
            : UIColor.black.withAlphaComponent(0.05)
    })

    /// Divider line — #E5E5E5 light
    static let appDivider = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.1)
            : UIColor(red: 0.898, green: 0.898, blue: 0.898, alpha: 1.0)  // #E5E5E5
    })

    /// Shadow color
    static let appShadow = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor.black.withAlphaComponent(0.5)
            : UIColor.black.withAlphaComponent(0.05)
    })

    // --- Status ---

    static let appSuccess = Color(UIColor(red: 0.204, green: 0.780, blue: 0.349, alpha: 1.0))  // #34C759

    static let appError = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 1.0, green: 0.271, blue: 0.227, alpha: 1.0)  // #FF4539
            : UIColor(red: 1.0, green: 0.231, blue: 0.188, alpha: 1.0)  // #FF3B30
    })

    static let appWarning = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 1.0, green: 0.839, blue: 0.039, alpha: 1.0)  // #FFD60A
            : UIColor(red: 1.0, green: 0.784, blue: 0.0, alpha: 1.0)    // #FFC800
    })
}
