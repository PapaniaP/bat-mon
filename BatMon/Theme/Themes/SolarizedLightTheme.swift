import SwiftUI

/// Solarized Light - precision light color scheme
/// Colors from: https://ethanschoonover.com/solarized/
struct SolarizedLightTheme: ColorTheme {
    let name = "Solarized Light"
    let id = "solarizedLight"

    // Base colors
    var background: Color { Color(hex: "#fdf6e3") }           // base3 (bg)
    var backgroundSecondary: Color { Color(hex: "#eee8d5") }  // base2
    var foreground: Color { Color(hex: "#657b83") }           // base00 (fg)
    var foregroundSecondary: Color { Color(hex: "#586e75") }  // base01
    var foregroundTertiary: Color { Color(hex: "#93a1a1") }   // base1

    // Semantic colors
    var accent: Color { Color(hex: "#268bd2") }               // blue
    var success: Color { Color(hex: "#859900") }              // green
    var warning: Color { Color(hex: "#b58900") }              // yellow
    var error: Color { Color(hex: "#dc322f") }                // red
    var critical: Color { Color(hex: "#dc322f") }             // red

    // Additional Solarized colors
    static let orange = Color(hex: "#cb4b16")
    static let magenta = Color(hex: "#d33682")
    static let violet = Color(hex: "#6c71c4")
    static let cyan = Color(hex: "#2aa198")
}
