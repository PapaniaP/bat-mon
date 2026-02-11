import SwiftUI

/// Environment key for the current color theme
private struct ColorThemeKey: EnvironmentKey {
    static let defaultValue: any ColorTheme = SystemTheme()
}

extension EnvironmentValues {
    /// The current color theme
    var colorTheme: any ColorTheme {
        get { self[ColorThemeKey.self] }
        set { self[ColorThemeKey.self] = newValue }
    }
}

extension View {
    /// Sets the color theme for this view and its descendants
    func colorTheme(_ theme: any ColorTheme) -> some View {
        environment(\.colorTheme, theme)
    }
}
