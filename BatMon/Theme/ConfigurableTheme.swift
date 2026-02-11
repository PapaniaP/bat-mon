import SwiftUI

/// Represents a theme from JSON that failed validation
struct InvalidTheme: Identifiable, Error {
    let id: String
    let name: String
    let missingFields: [String]

    var errorMessage: String {
        "Missing: \(missingFields.joined(separator: ", "))"
    }
}

/// A theme that can be configured from JSON
/// Conforms to ColorTheme protocol and derives missing colors from the 6 main colors
struct ConfigurableTheme: ColorTheme {
    let name: String
    let id: String

    // Stored colors (from JSON)
    private let _background: Color
    private let _backgroundSecondary: Color?
    private let _foreground: Color
    private let _foregroundSecondary: Color?
    private let _foregroundTertiary: Color?
    private let _accent: Color
    private let _success: Color
    private let _warning: Color
    private let _error: Color
    private let _critical: Color?
    private let _divider: Color?

    // MARK: - ColorTheme Protocol

    var background: Color { _background }

    var backgroundSecondary: Color {
        _backgroundSecondary ?? _background.lighter(by: 0.1)
    }

    var foreground: Color { _foreground }

    var foregroundSecondary: Color {
        _foregroundSecondary ?? _foreground.opacity(0.7)
    }

    var foregroundTertiary: Color {
        _foregroundTertiary ?? _foreground.opacity(0.4)
    }

    var accent: Color { _accent }
    var success: Color { _success }
    var warning: Color { _warning }
    var error: Color { _error }

    var critical: Color {
        _critical ?? _error
    }

    var divider: Color {
        _divider ?? _foreground.opacity(0.12)
    }

    // MARK: - Initialization from JSON

    /// Required color keys for a valid theme
    static let requiredColorKeys = ["background", "text", "accent", "healthy", "warning", "alert"]

    static func normalizedId(from name: String) -> String {
        name.lowercased().replacingOccurrences(of: " ", with: "_")
    }

    /// Validate JSON and return either a valid ConfigurableTheme or an InvalidTheme
    static func parse(from json: [String: Any]) -> Result<ConfigurableTheme, InvalidTheme> {
        guard let name = json["name"] as? String else {
            return .failure(InvalidTheme(
                id: "unknown_\(UUID().uuidString.prefix(8))",
                name: "Unknown",
                missingFields: ["name"]
            ))
        }

        let id = (json["id"] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nonEmpty ?? normalizedId(from: name)

        guard let colors = json["colors"] as? [String: String] else {
            return .failure(InvalidTheme(id: id, name: name, missingFields: ["colors"]))
        }

        // Check which required fields are missing
        let missingFields = requiredColorKeys.filter { colors[$0] == nil }

        if !missingFields.isEmpty {
            return .failure(InvalidTheme(id: id, name: name, missingFields: missingFields))
        }

        // All required fields present - create the theme
        let theme = ConfigurableTheme(
            name: name,
            id: id,
            background: Color(hex: colors["background"]!),
            foreground: Color(hex: colors["text"]!),
            accent: Color(hex: colors["accent"]!),
            success: Color(hex: colors["healthy"]!),
            warning: Color(hex: colors["warning"]!),
            error: Color(hex: colors["alert"]!),
            backgroundSecondary: colors["backgroundSecondary"].map { Color(hex: $0) },
            foregroundSecondary: colors["textSecondary"].map { Color(hex: $0) },
            foregroundTertiary: colors["textMuted"].map { Color(hex: $0) },
            critical: colors["critical"].map { Color(hex: $0) },
            divider: colors["divider"].map { Color(hex: $0) }
        )

        return .success(theme)
    }

    /// Initialize from a JSON dictionary
    /// - Parameters:
    ///   - json: Dictionary with "name" and "colors" keys
    /// - Returns: nil if required fields are missing
    init?(from json: [String: Any]) {
        guard case .success(let theme) = Self.parse(from: json) else {
            return nil
        }
        self = theme
    }

    /// Initialize with explicit values (for programmatic creation)
    init(
        name: String,
        id: String? = nil,
        background: Color,
        foreground: Color,
        accent: Color,
        success: Color,
        warning: Color,
        error: Color,
        backgroundSecondary: Color? = nil,
        foregroundSecondary: Color? = nil,
        foregroundTertiary: Color? = nil,
        critical: Color? = nil,
        divider: Color? = nil
    ) {
        self.name = name
        self.id = id?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty ?? Self.normalizedId(from: name)
        self._background = background
        self._foreground = foreground
        self._accent = accent
        self._success = success
        self._warning = warning
        self._error = error
        self._backgroundSecondary = backgroundSecondary
        self._foregroundSecondary = foregroundSecondary
        self._foregroundTertiary = foregroundTertiary
        self._critical = critical
        self._divider = divider
    }

    // MARK: - Export to JSON

    /// Convert theme to JSON dictionary for saving
    func toJSON() -> [String: Any] {
        var colors: [String: String] = [
            "background": _background.toHex(),
            "text": _foreground.toHex(),
            "accent": _accent.toHex(),
            "healthy": _success.toHex(),
            "warning": _warning.toHex(),
            "alert": _error.toHex()
        ]

        // Include optional overrides if they were explicitly set
        if let bg2 = _backgroundSecondary { colors["backgroundSecondary"] = bg2.toHex() }
        if let fg2 = _foregroundSecondary { colors["textSecondary"] = fg2.toHex() }
        if let fg3 = _foregroundTertiary { colors["textMuted"] = fg3.toHex() }
        if let crit = _critical { colors["critical"] = crit.toHex() }
        if let div = _divider { colors["divider"] = div.toHex() }

        return [
            "id": id,
            "name": name,
            "colors": colors
        ]
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}

// MARK: - Color Extension for Lightening

extension Color {
    /// Lightens the color by the given amount (0.0 to 1.0)
    func lighter(by amount: Double) -> Color {
        guard let components = NSColor(self).usingColorSpace(.deviceRGB) else {
            return self
        }

        let r = min(1.0, components.redComponent + amount)
        let g = min(1.0, components.greenComponent + amount)
        let b = min(1.0, components.blueComponent + amount)

        return Color(red: r, green: g, blue: b)
    }
}
