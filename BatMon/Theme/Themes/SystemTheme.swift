import SwiftUI

/// Uses SwiftUI semantic colors - adapts to light/dark mode automatically
struct SystemTheme: ColorTheme {
    let name = "System"
    let id = "system"

    // Base colors - these adapt to system appearance
    var background: Color { Color(nsColor: .windowBackgroundColor) }
    var backgroundSecondary: Color { Color.primary.opacity(0.05) }
    var foreground: Color { .primary }
    var foregroundSecondary: Color { .secondary }
    var foregroundTertiary: Color { Color.primary.opacity(0.3) }

    // Semantic colors
    var accent: Color { .accentColor }
    var success: Color { .green }
    var warning: Color { .orange }
    var error: Color { .red }
    var critical: Color { .red }
}
