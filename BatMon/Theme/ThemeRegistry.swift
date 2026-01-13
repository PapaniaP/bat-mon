import SwiftUI

/// Central registry for all available color themes
/// Combines hardcoded themes with user-configurable themes from ~/.config/bat-mon/themes.json
class ThemeRegistry: ObservableObject {
    static let shared = ThemeRegistry()

    /// Hardcoded themes that are always available (cannot be deleted)
    static let hardcodedThemes: [any ColorTheme] = [
        SystemTheme(),
        GruvboxTheme(),
        GruvboxLightTheme(),
        TokyoNightTheme(),
        SolarizedLightTheme()
    ]

    /// Custom themes loaded from config file
    @Published private(set) var customThemes: [ConfigurableTheme] = []

    /// Invalid themes from config file (missing required fields)
    @Published private(set) var invalidThemes: [InvalidTheme] = []

    /// All available themes (hardcoded + custom)
    var allThemes: [any ColorTheme] {
        Self.hardcodedThemes + customThemes
    }

    /// The default theme (System)
    static var defaultTheme: any ColorTheme { SystemTheme() }

    // MARK: - Initialization

    private init() {
        reloadCustomThemes()
        CustomThemeLoader.shared.startWatching { [weak self] in
            self?.reloadCustomThemes()
        }
    }

    deinit {
        CustomThemeLoader.shared.stopWatching()
    }

    // MARK: - Public API

    /// Look up a theme by its ID
    func theme(for id: String) -> any ColorTheme {
        allThemes.first { $0.id == id } ?? Self.defaultTheme
    }

    /// Reload custom themes from the config file
    func reloadCustomThemes() {
        let result = CustomThemeLoader.shared.loadThemesWithValidation()
        customThemes = result.validThemes
        invalidThemes = result.invalidThemes
    }

    /// Check if a theme is hardcoded (not editable)
    func isHardcoded(_ themeId: String) -> Bool {
        Self.hardcodedThemes.contains { $0.id == themeId }
    }

    /// Check if a theme is from the config file (editable)
    func isCustom(_ themeId: String) -> Bool {
        customThemes.contains { $0.id == themeId }
    }

    /// Add or update a custom theme
    func saveCustomTheme(_ theme: ConfigurableTheme) throws {
        try CustomThemeLoader.shared.updateTheme(theme)
        reloadCustomThemes()
    }

    /// Remove a custom theme
    func removeCustomTheme(withId id: String) throws {
        guard !isHardcoded(id) else { return }
        try CustomThemeLoader.shared.removeTheme(withId: id)
        reloadCustomThemes()
    }

    /// Initialize default themes.json if it doesn't exist
    func initializeDefaultThemesIfNeeded() {
        CustomThemeLoader.shared.initializeDefaultThemesIfNeeded()
        reloadCustomThemes()
    }
}
