import SwiftUI

/// Gruvbox Light - warm retro light palette
/// Colors from: https://github.com/morhetz/gruvbox
struct GruvboxLightTheme: ColorTheme {
    let name = "Gruvbox Light"
    let id = "gruvboxLight"

    // Base colors
    var background: Color { Color(hex: "#fbf1c7") }           // light0 (bg)
    var backgroundSecondary: Color { Color(hex: "#ebdbb2") }  // light1
    var foreground: Color { Color(hex: "#3c3836") }           // dark1 (fg)
    var foregroundSecondary: Color { Color(hex: "#504945") }  // dark2
    var foregroundTertiary: Color { Color(hex: "#928374") }   // gray

    // Semantic colors (using neutral variants for light theme)
    var accent: Color { Color(hex: "#d79921") }               // yellow
    var success: Color { Color(hex: "#98971a") }              // green
    var warning: Color { Color(hex: "#d65d0e") }              // orange
    var error: Color { Color(hex: "#cc241d") }                // red
    var critical: Color { Color(hex: "#cc241d") }             // red

    // Additional Gruvbox Light colors
    static let aqua = Color(hex: "#689d6a")
    static let blue = Color(hex: "#458588")
    static let purple = Color(hex: "#b16286")
}
