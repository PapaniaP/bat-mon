import SwiftUI

/// Protocol defining a complete color theme for BatMon
protocol ColorTheme {
    // MARK: - Identity
    var name: String { get }
    var id: String { get }

    // MARK: - Base Colors
    /// Main background color (used fully by TUI, ignored by system layouts)
    var background: Color { get }
    /// Secondary background for hover states, cards
    var backgroundSecondary: Color { get }
    /// Primary text color
    var foreground: Color { get }
    /// Secondary text color
    var foregroundSecondary: Color { get }
    /// Tertiary/muted text color
    var foregroundTertiary: Color { get }

    // MARK: - Semantic Colors (used by ALL layouts)
    /// Accent/highlight color
    var accent: Color { get }
    /// Success state - connected, good battery (>40%)
    var success: Color { get }
    /// Warning state - medium battery (21-40%), reconnecting
    var warning: Color { get }
    /// Error state - low battery (11-20%), failed
    var error: Color { get }
    /// Critical state - very low battery (0-10%)
    var critical: Color { get }

    // MARK: - Derived Colors
    /// Color for dividers/separators
    var divider: Color { get }

    // MARK: - Battery Color
    /// Returns the appropriate color for a battery percentage
    func batteryColor(for percentage: Int) -> Color
}

// MARK: - Default Implementations

extension ColorTheme {
    var divider: Color {
        foregroundTertiary.opacity(0.3)
    }

    func batteryColor(for percentage: Int) -> Color {
        let clamped = min(max(percentage, 0), 100)
        switch clamped {
        case 0...10: return critical
        case 11...20: return error
        case 21...40: return warning
        default: return success
        }
    }
}
