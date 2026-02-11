import Foundation
import SwiftUI
import os.log

/// Handles loading, saving, and managing custom themes from the user's Application Support directory.
class CustomThemeLoader {
    static let shared = CustomThemeLoader()

    private let logger = Logger(subsystem: "com.paolo.bat-mon", category: "CustomThemeLoader")

    // File watching
    private var fileDescriptor: Int32 = -1
    private var dispatchSource: DispatchSourceFileSystemObject?

    /// Path to the config directory
    /// Uses Application Support for sandboxed apps
    private var configDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")
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
        let rawJSON: [[String: Any]]  // Preserves original JSON for save operations
    }

    /// Load all custom themes from the config file
    /// Returns empty array if file doesn't exist or is invalid
    func loadThemes() -> [ConfigurableTheme] {
        loadThemesWithValidation().validThemes
    }

    /// Load themes and return both valid themes and invalid themes with error info
    func loadThemesWithValidation() -> LoadResult {
        guard FileManager.default.fileExists(atPath: themesFilePath.path) else {
            logger.info("No themes.json found at \(self.themesFilePath.path)")
            return LoadResult(validThemes: [], invalidThemes: [], rawJSON: [])
        }

        do {
            let data = try Data(contentsOf: themesFilePath)
            guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                logger.error("themes.json is not a valid array")
                return LoadResult(validThemes: [], invalidThemes: [], rawJSON: [])
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
            return LoadResult(validThemes: validThemes, invalidThemes: invalidThemes, rawJSON: jsonArray)
        } catch {
            logger.error("Failed to load themes.json: \(error.localizedDescription)")
            return LoadResult(validThemes: [], invalidThemes: [], rawJSON: [])
        }
    }

    /// Save themes to the config file (replaces all themes)
    func saveThemes(_ themes: [ConfigurableTheme]) throws {
        try ensureConfigDirectoryExists()

        let jsonArray = themes.map { $0.toJSON() }
        let data = try JSONSerialization.data(withJSONObject: jsonArray, options: [.prettyPrinted, .sortedKeys])

        try data.write(to: themesFilePath, options: .atomic)
        logger.info("Saved \(themes.count) themes to \(self.themesFilePath.path)")
    }

    /// Save raw JSON array to the config file (preserves invalid themes)
    private func saveRawJSON(_ jsonArray: [[String: Any]]) throws {
        try ensureConfigDirectoryExists()

        let data = try JSONSerialization.data(withJSONObject: jsonArray, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: themesFilePath, options: .atomic)
        logger.info("Saved \(jsonArray.count) themes to \(self.themesFilePath.path)")
    }

    /// Helper to get theme ID from raw JSON
    private func themeId(from json: [String: Any]) -> String? {
        if let id = json["id"] as? String {
            let trimmed = id.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }
        guard let name = json["name"] as? String else { return nil }
        return ConfigurableTheme.normalizedId(from: name)
    }

    /// Add a new theme to the config file (preserves invalid themes)
    func addTheme(_ theme: ConfigurableTheme) throws {
        var rawJSON = loadThemesWithValidation().rawJSON

        // Remove any existing theme with the same ID
        rawJSON.removeAll { themeId(from: $0) == theme.id }
        rawJSON.append(theme.toJSON())

        try saveRawJSON(rawJSON)
    }

    /// Update an existing theme in the config file (preserves invalid themes)
    func updateTheme(_ theme: ConfigurableTheme) throws {
        var rawJSON = loadThemesWithValidation().rawJSON

        if let index = rawJSON.firstIndex(where: { themeId(from: $0) == theme.id }) {
            rawJSON[index] = theme.toJSON()
        } else {
            rawJSON.append(theme.toJSON())
        }

        try saveRawJSON(rawJSON)
    }

    /// Remove a theme from the config file (preserves invalid themes)
    func removeTheme(withId id: String) throws {
        var rawJSON = loadThemesWithValidation().rawJSON
        rawJSON.removeAll { themeId(from: $0) == id }
        try saveRawJSON(rawJSON)
    }

    /// Check if the themes.json file exists
    func themesFileExists() -> Bool {
        FileManager.default.fileExists(atPath: themesFilePath.path)
    }

    /// Create the config directory and default themes.json if they don't exist
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

    /// Start watching the themes.json file for changes
    func startWatching(onChange: @escaping () -> Void) {
        stopWatching()

        if !themesFileExists() {
            initializeDefaultThemesIfNeeded()
        }

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

        dispatchSource?.setEventHandler { [weak self] in
            guard let self else { return }
            let events = self.dispatchSource?.data ?? []
            onChange()

            // Atomic writes replace the file and invalidate the old file descriptor.
            if events.contains(.delete) || events.contains(.rename) {
                self.logger.info("themes.json watcher invalidated; restarting")
                self.stopWatching()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.startWatching(onChange: onChange)
                }
            }
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

    /// Stop watching the themes.json file
    func stopWatching() {
        dispatchSource?.cancel()
        dispatchSource = nil
    }

    // MARK: - Private Helpers

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
