import SwiftUI

/// Gruvbox Dark - warm retro color palette
/// Colors from: https://github.com/morhetz/gruvbox
struct GruvboxTheme: ColorTheme {
    let name = "Gruvbox"
    let id = "gruvbox"

    // Base colors
    var background: Color { Color(red: 0.16, green: 0.15, blue: 0.13) }           // #282828 bg0
    var backgroundSecondary: Color { Color(red: 0.23, green: 0.22, blue: 0.21) }  // #3c3836 bg1
    var foreground: Color { Color(red: 0.92, green: 0.86, blue: 0.70) }           // #ebdbb2 fg1
    var foregroundSecondary: Color { Color(red: 0.66, green: 0.60, blue: 0.52) }  // #a89984 gray
    var foregroundTertiary: Color { Color(red: 0.50, green: 0.45, blue: 0.39) }   // #7c6f64 bg4

    // Semantic colors (using bright variants for better visibility)
    var accent: Color { Color(red: 0.98, green: 0.74, blue: 0.18) }               // #fabd2f yellow bright
    var success: Color { Color(red: 0.72, green: 0.73, blue: 0.15) }              // #b8bb26 green bright
    var warning: Color { Color(red: 1.0, green: 0.50, blue: 0.10) }               // #fe8019 orange bright
    var error: Color { Color(red: 0.98, green: 0.29, blue: 0.20) }                // #fb4934 red bright
    var critical: Color { Color(red: 0.98, green: 0.29, blue: 0.20) }             // #fb4934 red bright

    // Additional Gruvbox colors
    static let aqua = Color(red: 0.56, green: 0.75, blue: 0.49)                   // #8ec07c aqua bright
    static let blue = Color(red: 0.51, green: 0.65, blue: 0.60)                   // #83a598 blue bright
    static let purple = Color(red: 0.83, green: 0.54, blue: 0.61)                 // #d3869b purple bright
}
