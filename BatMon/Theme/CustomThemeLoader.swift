import Foundation
import SwiftUI
import os.log

/// Handles loading, saving, and managing custom themes from ~/.config/bat-mon/themes.json
class CustomThemeLoader {
    static let shared = CustomThemeLoader()

    private let logger = Logger(subsystem: "com.paolo.bat-mon", category: "CustomThemeLoader")

    // File watching
    private var fileDescriptor: Int32 = -1
    private var dispatchSource: DispatchSourceFileSystemObject?

    /// Path to the config directory
    /// Uses Application Support for sandboxed apps
    private var configDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("BatMon")
    }

    /// Path to the themes.json file
    private var themesFilePath: URL {
        configDirectory.appendingPathComponent("themes.json")
    }

    // MARK: - Public API

    /// Result of loading themes - includes both valid and invalid themes
    struct LoadResult {
        let validThemes: [ConfigurableTheme]
        let invalidThemes: [InvalidTheme]
    }

    /// Load all custom themes from the config file
    /// Load configured themes from persistent storage, returning only successfully parsed themes.
    /// - Returns: An array of `ConfigurableTheme` instances parsed successfully from `themes.json`; invalid or malformed entries are omitted.
    func loadThemes() -> [ConfigurableTheme] {
        loadThemesWithValidation().validThemes
    }

    /// Loads and validates themes from the themes.json file, returning both successfully parsed themes and parsing errors.
    /// Attempts to read themes.json as a JSON array and validates each object with `ConfigurableTheme.parse(from:)`. If the file is missing or if reading/parsing fails, an empty `LoadResult` is returned.
    /// - Returns: A `LoadResult` containing `validThemes` (parsed `ConfigurableTheme` instances) and `invalidThemes` (`InvalidTheme` entries describing validation failures).
    func loadThemesWithValidation() -> LoadResult {
        guard FileManager.default.fileExists(atPath: themesFilePath.path) else {
            logger.info("No themes.json found at \(self.themesFilePath.path)")
            return LoadResult(validThemes: [], invalidThemes: [])
        }

        do {
            let data = try Data(contentsOf: themesFilePath)
            guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                logger.error("themes.json is not a valid array")
                return LoadResult(validThemes: [], invalidThemes: [])
            }

            var validThemes: [ConfigurableTheme] = []
            var invalidThemes: [InvalidTheme] = []

            for json in jsonArray {
                switch ConfigurableTheme.parse(from: json) {
                case .success(let theme):
                    validThemes.append(theme)
                case .failure(let invalid):
                    invalidThemes.append(invalid)
                    logger.warning("Invalid theme '\(invalid.name)': \(invalid.errorMessage)")
                }
            }

            logger.info("Loaded \(validThemes.count) valid themes, \(invalidThemes.count) invalid")
            return LoadResult(validThemes: validThemes, invalidThemes: invalidThemes)
        } catch {
            logger.error("Failed to load themes.json: \(error.localizedDescription)")
            return LoadResult(validThemes: [], invalidThemes: [])
        }
    }

    /// Persist the given themes to the `themes.json` file in the app's configuration directory.
    /// - Parameters:
    ///   - themes: The list of `ConfigurableTheme` objects to write; this will replace the existing themes file.
    /// - Throws: An error if creating/ensuring the configuration directory, serializing the themes to JSON, or writing the file fails.
    func saveThemes(_ themes: [ConfigurableTheme]) throws {
        try ensureConfigDirectoryExists()

        let jsonArray = themes.map { $0.toJSON() }
        let data = try JSONSerialization.data(withJSONObject: jsonArray, options: [.prettyPrinted, .sortedKeys])

        try data.write(to: themesFilePath, options: .atomic)
        logger.info("Saved \(themes.count) themes to \(self.themesFilePath.path)")
    }

    /// Adds a theme to the persisted themes, replacing any existing theme with the same id.
    /// - Parameters:
    ///   - theme: The `ConfigurableTheme` to add or replace in the stored themes list.
    /// - Throws: An error if persisting the updated themes to disk fails.
    func addTheme(_ theme: ConfigurableTheme) throws {
        var themes = loadThemes()

        // Check for duplicate names
        themes.removeAll { $0.id == theme.id }
        themes.append(theme)

        try saveThemes(themes)
    }

    /// Adds or updates a configurable theme in the persisted themes list.
    /// - Parameters:
    ///   - theme: The theme to add or update. If a theme with the same `id` already exists it will be replaced; otherwise the theme is appended.
    /// - Throws: An error if saving the updated themes to disk fails.
    func updateTheme(_ theme: ConfigurableTheme) throws {
        var themes = loadThemes()

        if let index = themes.firstIndex(where: { $0.id == theme.id }) {
            themes[index] = theme
        } else {
            themes.append(theme)
        }

        try saveThemes(themes)
    }

    /// Removes any persisted theme with the specified identifier.
    /// - Parameters:
    ///   - id: The unique identifier of the theme to remove.
    /// - Throws: An error if updating the stored themes fails (for example, if the config directory cannot be created or the themes file cannot be written).
    func removeTheme(withId id: String) throws {
        var themes = loadThemes()
        themes.removeAll { $0.id == id }
        try saveThemes(themes)
    }

    /// Checks whether the `themes.json` file exists in the application's config directory.
    /// - Returns: `true` if `themes.json` exists at the configured path, `false` otherwise.
    func themesFileExists() -> Bool {
        FileManager.default.fileExists(atPath: themesFilePath.path)
    }

    /// Creates a themes.json populated with the built-in default themes if no themes file exists.
    /// 
    /// If a themes.json already exists, the method does nothing. Otherwise it ensures the configuration
    /// directory exists and writes the predefined default themes to themes.json. Failure to create the
    /// directory or write the file will be logged as an error.
    func initializeDefaultThemesIfNeeded() {
        guard !themesFileExists() else {
            logger.info("themes.json already exists, skipping initialization")
            return
        }

        do {
            try ensureConfigDirectoryExists()
            try saveThemes(Self.defaultThemes)
            logger.info("Created default themes.json with \(Self.defaultThemes.count) themes")
        } catch {
            logger.error("Failed to create default themes.json: \(error.localizedDescription)")
        }
    }

    // MARK: - File Watching

    /// Begins monitoring the persisted themes.json file for external changes and invokes the provided callback when modifications occur.
    /// - Parameters:
    ///   - onChange: Closure invoked whenever the themes file is written, deleted, or renamed.
    /// - Note: Any existing watcher is stopped before starting a new one. If the file cannot be opened for event monitoring, the watcher will not be started.
    func startWatching(onChange: @escaping () -> Void) {
        stopWatching()

        let path = themesFilePath.path
        fileDescriptor = open(path, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            logger.warning("Could not open file for watching: \(path)")
            return
        }

        dispatchSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .delete, .rename],
            queue: .main
        )

        dispatchSource?.setEventHandler {
            onChange()
        }

        dispatchSource?.setCancelHandler { [weak self] in
            if let fd = self?.fileDescriptor, fd >= 0 {
                close(fd)
            }
            self?.fileDescriptor = -1
        }

        dispatchSource?.resume()
        logger.info("Started watching themes.json for changes")
    }

    /// Stops observing changes to the themes file and releases the watcher.
    /// 
    /// Cancels any active file-system dispatch source and clears the stored reference so watching can be restarted.
    func stopWatching() {
        dispatchSource?.cancel()
        dispatchSource = nil
    }

    /// Ensures the application's configuration directory exists, creating it if necessary.
    /// - Throws: A `FileManager` error if creating the directory fails.

    private func ensureConfigDirectoryExists() throws {
        if !FileManager.default.fileExists(atPath: configDirectory.path) {
            try FileManager.default.createDirectory(at: configDirectory, withIntermediateDirectories: true)
            logger.info("Created config directory at \(self.configDirectory.path)")
        }
    }

    // MARK: - Default Themes

    /// Default themes to populate themes.json on first launch
    static let defaultThemes: [ConfigurableTheme] = [
        // GitHub Dark
        ConfigurableTheme(
            name: "GitHub Dark",
            background: Color(hex: "#0d1117"),
            foreground: Color(hex: "#c6cdd5"),
            accent: Color(hex: "#77bdfb"),
            success: Color(hex: "#7ce38b"),
            warning: Color(hex: "#faa356"),
            error: Color(hex: "#fa7970"),
            backgroundSecondary: Color(hex: "#161b22"),
            foregroundSecondary: Color(hex: "#7d8590")
        ),
        // Dracula
        ConfigurableTheme(
            name: "Dracula",
            background: Color(hex: "#282a36"),
            foreground: Color(hex: "#f8f8f2"),
            accent: Color(hex: "#bd93f9"),
            success: Color(hex: "#50fa7b"),
            warning: Color(hex: "#ffb86c"),
            error: Color(hex: "#ff5555"),
            backgroundSecondary: Color(hex: "#44475a"),
            foregroundSecondary: Color(hex: "#6272a4")
        ),
        // Nord
        ConfigurableTheme(
            name: "Nord",
            background: Color(hex: "#2e3440"),
            foreground: Color(hex: "#eceff4"),
            accent: Color(hex: "#88c0d0"),
            success: Color(hex: "#a3be8c"),
            warning: Color(hex: "#ebcb8b"),
            error: Color(hex: "#bf616a"),
            backgroundSecondary: Color(hex: "#3b4252"),
            foregroundSecondary: Color(hex: "#d8dee9")
        ),
        // Catppuccin Mocha
        ConfigurableTheme(
            name: "Catppuccin",
            background: Color(hex: "#1e1e2e"),
            foreground: Color(hex: "#cdd6f4"),
            accent: Color(hex: "#cba6f7"),
            success: Color(hex: "#a6e3a1"),
            warning: Color(hex: "#f9e2af"),
            error: Color(hex: "#f38ba8"),
            backgroundSecondary: Color(hex: "#313244"),
            foregroundSecondary: Color(hex: "#a6adc8")
        )
    ]
}