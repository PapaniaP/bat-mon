//
//  WidgetTheme.swift
//  BatMonWidget
//
//  Theme colors for widgets - reads theme preference from shared storage
//

import SwiftUI

// MARK: - Theme Reader

/// Reads theme preference from shared UserDefaults
struct WidgetThemeReader {
    private static let sharedDefaults = UserDefaults(suiteName: "group.com.paolo.bat-mon")

    static var themeId: String {
        sharedDefaults?.string(forKey: "widgetThemeId") ?? "system"
    }

    static var menuLayout: String {
        sharedDefaults?.string(forKey: "widgetMenuLayout") ?? "native"
    }

    static var currentTheme: WidgetTheme {
        WidgetTheme.theme(for: themeId)
    }
}

// MARK: - Widget Theme

/// Simplified theme for widgets with all necessary colors
struct WidgetTheme {
    let id: String
    let name: String

    // Base colors
    let background: Color
    let backgroundSecondary: Color
    let foreground: Color
    let foregroundSecondary: Color
    let foregroundTertiary: Color

    // Semantic colors
    let accent: Color
    let success: Color
    let warning: Color
    let error: Color
    let critical: Color

    /// Returns battery color based on percentage
    func batteryColor(for percentage: Int) -> Color {
        let clamped = min(max(percentage, 0), 100)
        switch clamped {
        case 0...10: return critical
        case 11...20: return error
        case 21...40: return warning
        default: return success
        }
    }

    // MARK: - Predefined Themes

    static func theme(for id: String) -> WidgetTheme {
        switch id {
        case "gruvbox": return .gruvbox
        case "gruvbox_light": return .gruvboxLight
        case "tokyoNight": return .tokyoNight
        case "solarized_light": return .solarizedLight
        default: return .system
        }
    }

    /// System theme - adapts to light/dark mode
    static let system = WidgetTheme(
        id: "system",
        name: "System",
        background: Color(NSColor.windowBackgroundColor),
        backgroundSecondary: Color(NSColor.controlBackgroundColor),
        foreground: Color.primary,
        foregroundSecondary: Color.secondary,
        foregroundTertiary: Color.secondary.opacity(0.6),
        accent: Color.accentColor,
        success: Color.green,
        warning: Color.orange,
        error: Color.red,
        critical: Color.red
    )

    /// Gruvbox Dark theme
    static let gruvbox = WidgetTheme(
        id: "gruvbox",
        name: "Gruvbox",
        background: Color(red: 0.16, green: 0.15, blue: 0.13),
        backgroundSecondary: Color(red: 0.20, green: 0.19, blue: 0.17),
        foreground: Color(red: 0.92, green: 0.86, blue: 0.70),
        foregroundSecondary: Color(red: 0.66, green: 0.60, blue: 0.52),
        foregroundTertiary: Color(red: 0.50, green: 0.45, blue: 0.40),
        accent: Color(red: 0.98, green: 0.74, blue: 0.02),
        success: Color(red: 0.72, green: 0.73, blue: 0.15),
        warning: Color(red: 0.98, green: 0.74, blue: 0.02),
        error: Color(red: 0.80, green: 0.14, blue: 0.11),
        critical: Color(red: 0.80, green: 0.14, blue: 0.11)
    )

    /// Gruvbox Light theme
    static let gruvboxLight = WidgetTheme(
        id: "gruvbox_light",
        name: "Gruvbox Light",
        background: Color(red: 0.98, green: 0.94, blue: 0.84),
        backgroundSecondary: Color(red: 0.93, green: 0.89, blue: 0.79),
        foreground: Color(red: 0.24, green: 0.22, blue: 0.21),
        foregroundSecondary: Color(red: 0.40, green: 0.38, blue: 0.33),
        foregroundTertiary: Color(red: 0.55, green: 0.52, blue: 0.45),
        accent: Color(red: 0.85, green: 0.53, blue: 0.10),
        success: Color(red: 0.47, green: 0.53, blue: 0.07),
        warning: Color(red: 0.85, green: 0.53, blue: 0.10),
        error: Color(red: 0.75, green: 0.14, blue: 0.09),
        critical: Color(red: 0.75, green: 0.14, blue: 0.09)
    )

    /// Tokyo Night theme
    static let tokyoNight = WidgetTheme(
        id: "tokyoNight",
        name: "Tokyo Night",
        background: Color(red: 0.10, green: 0.11, blue: 0.15),
        backgroundSecondary: Color(red: 0.14, green: 0.15, blue: 0.20),
        foreground: Color(red: 0.66, green: 0.68, blue: 0.82),
        foregroundSecondary: Color(red: 0.45, green: 0.48, blue: 0.58),
        foregroundTertiary: Color(red: 0.35, green: 0.38, blue: 0.48),
        accent: Color(red: 0.49, green: 0.67, blue: 0.98),
        success: Color(red: 0.45, green: 0.83, blue: 0.68),
        warning: Color(red: 0.88, green: 0.65, blue: 0.42),
        error: Color(red: 0.96, green: 0.45, blue: 0.52),
        critical: Color(red: 0.96, green: 0.45, blue: 0.52)
    )

    /// Solarized Light theme
    static let solarizedLight = WidgetTheme(
        id: "solarized_light",
        name: "Solarized Light",
        background: Color(red: 0.99, green: 0.96, blue: 0.89),
        backgroundSecondary: Color(red: 0.93, green: 0.91, blue: 0.84),
        foreground: Color(red: 0.40, green: 0.48, blue: 0.51),
        foregroundSecondary: Color(red: 0.51, green: 0.58, blue: 0.59),
        foregroundTertiary: Color(red: 0.58, green: 0.63, blue: 0.63),
        accent: Color(red: 0.15, green: 0.55, blue: 0.82),
        success: Color(red: 0.52, green: 0.60, blue: 0.00),
        warning: Color(red: 0.71, green: 0.54, blue: 0.00),
        error: Color(red: 0.86, green: 0.20, blue: 0.18),
        critical: Color(red: 0.86, green: 0.20, blue: 0.18)
    )
}

// MARK: - Date Formatting Extension

extension Date {
    /// Returns a human-readable time ago string
    func widgetTimeAgo() -> String {
        let seconds = Int(-self.timeIntervalSinceNow)

        if seconds < 60 {
            return "just now"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes)m ago"
        } else if seconds < 86400 {
            let hours = seconds / 3600
            return "\(hours)h ago"
        } else {
            let days = seconds / 86400
            return "\(days)d ago"
        }
    }
}
