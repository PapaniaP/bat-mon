import SwiftUI

/// Tokyo Night - cool modern color palette
struct TokyoNightTheme: ColorTheme {
    let name = "Tokyo Night"
    let id = "tokyoNight"

    // Base colors
    var background: Color { Color(red: 0.10, green: 0.11, blue: 0.15) }           // #1a1b26
    var backgroundSecondary: Color { Color(red: 0.14, green: 0.15, blue: 0.20) }  // #24283b
    var foreground: Color { Color(red: 0.66, green: 0.71, blue: 0.86) }           // #a9b1d6
    var foregroundSecondary: Color { Color(red: 0.33, green: 0.38, blue: 0.55) }  // #565f89
    var foregroundTertiary: Color { Color(red: 0.25, green: 0.28, blue: 0.40) }   // #3b4261

    // Semantic colors
    var accent: Color { Color(red: 0.73, green: 0.52, blue: 0.94) }               // #bb9af7 magenta
    var success: Color { Color(red: 0.58, green: 0.87, blue: 0.60) }              // #9ece6a green
    var warning: Color { Color(red: 0.88, green: 0.77, blue: 0.49) }              // #e0af68 yellow
    var error: Color { Color(red: 0.95, green: 0.45, blue: 0.45) }                // #f7768e red
    var critical: Color { Color(red: 0.95, green: 0.45, blue: 0.45) }             // #f7768e red

    // Additional Tokyo Night colors for TUI
    static let blue = Color(red: 0.48, green: 0.64, blue: 0.90)                   // #7aa2f7
    static let cyan = Color(red: 0.49, green: 0.85, blue: 0.87)                   // #7dcfff
}
