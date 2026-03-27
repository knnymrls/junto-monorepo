//
//  ThemeManager.swift
//  mkrs-world
//
//  Observable theme manager for light/dark mode
//

import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    @AppStorage("selectedTheme") var selectedTheme: AppearanceTheme = .system

    var selectedAppearance: AppearanceTheme {
        get { selectedTheme }
        set { selectedTheme = newValue }
    }

    static let shared = ThemeManager()

    init() {}
}

enum AppearanceTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
