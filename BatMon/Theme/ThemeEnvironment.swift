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
    /// Sets the color theme for this view and its descendant views.
    /// - Parameters:
    ///   - theme: The `ColorTheme` to inject into the environment.
    /// - Returns: A view that applies the given color theme to the view hierarchy.
    func colorTheme(_ theme: any ColorTheme) -> some View {
        environment(\.colorTheme, theme)
    }
}