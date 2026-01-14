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

    /// Selects the theme with the specified identifier or falls back to the default theme.
    /// - Parameters:
    ///   - id: The identifier of the theme to look up.
    /// - Returns: The theme matching `id`, or the registry's default theme if no match is found.
    func theme(for id: String) -> any ColorTheme {
        allThemes.first { $0.id == id } ?? Self.defaultTheme
    }

    /// Reloads user-configurable themes from persistent configuration and updates the registry state.
    /// 
    /// Replaces `customThemes` with the validated valid themes and `invalidThemes` with any entries that failed validation.
    func reloadCustomThemes() {
        let result = CustomThemeLoader.shared.loadThemesWithValidation()
        customThemes = result.validThemes
        invalidThemes = result.invalidThemes
    }

    /// Checks whether a theme identifier refers to a hardcoded theme.
    /// - Returns: `true` if the theme id corresponds to a hardcoded theme, `false` otherwise.
    func isHardcoded(_ themeId: String) -> Bool {
        Self.hardcodedThemes.contains { $0.id == themeId }
    }

    /// Checks whether a theme identifier corresponds to a user-configurable theme.
    /// - Parameters:
    ///   - themeId: The identifier of the theme to check.
    /// - Returns: `true` if a custom theme with the given id exists, `false` otherwise.
    func isCustom(_ themeId: String) -> Bool {
        customThemes.contains { $0.id == themeId }
    }

    /// Saves or updates a configurable theme in the persistent custom themes store and refreshes the registry.
    /// - Parameters:
    ///   - theme: The configurable theme to add or update.
    /// - Throws: An error if the theme cannot be persisted to the custom themes configuration.
    func saveCustomTheme(_ theme: ConfigurableTheme) throws {
        try CustomThemeLoader.shared.updateTheme(theme)
        reloadCustomThemes()
    }

    /// Removes the user-configurable theme with the given identifier.
    /// If the identifier corresponds to a hardcoded theme, the call has no effect.
    /// On successful removal, the registry reloads its custom themes to reflect the change.
    /// - Parameter id: The identifier of the custom theme to remove.
    /// - Throws: An error from `CustomThemeLoader` if the theme could not be removed.
    func removeCustomTheme(withId id: String) throws {
        guard !isHardcoded(id) else { return }
        try CustomThemeLoader.shared.removeTheme(withId: id)
        reloadCustomThemes()
    }

    /// Creates default theme files in the configuration if they are missing and reloads the registry's custom and invalid themes.
    /// After calling this, `customThemes` and `invalidThemes` are refreshed to reflect any newly created or changed theme definitions.
    func initializeDefaultThemesIfNeeded() {
        CustomThemeLoader.shared.initializeDefaultThemesIfNeeded()
        reloadCustomThemes()
    }
}