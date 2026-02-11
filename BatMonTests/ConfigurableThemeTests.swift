import XCTest
import AppKit
import SwiftUI

final class ConfigurableThemeTests: XCTestCase {
    func testNormalizedIdLowercasesAndReplacesSpaces() {
        let id = ConfigurableTheme.normalizedId(from: "My Theme Name")
        XCTAssertEqual(id, "my_theme_name")
    }

    func testParseUsesExplicitIdWhenPresent() {
        let json: [String: Any] = [
            "id": "stable_theme_id",
            "name": "My Theme",
            "colors": requiredColors
        ]

        let parsed = ConfigurableTheme.parse(from: json)
        guard case .success(let theme) = parsed else {
            XCTFail("Expected theme parse success")
            return
        }

        XCTAssertEqual(theme.id, "stable_theme_id")
    }

    func testParseFallsBackToNormalizedNameWithoutId() {
        let json: [String: Any] = [
            "name": "My Theme",
            "colors": requiredColors
        ]

        let parsed = ConfigurableTheme.parse(from: json)
        guard case .success(let theme) = parsed else {
            XCTFail("Expected theme parse success")
            return
        }

        XCTAssertEqual(theme.id, "my_theme")
    }

    func testInitializerPreservesProvidedId() {
        let theme = ConfigurableTheme(
            name: "Renamed Theme",
            id: "original_theme_id",
            background: .black,
            foreground: .white,
            accent: .blue,
            success: .green,
            warning: .orange,
            error: .red
        )

        XCTAssertEqual(theme.id, "original_theme_id")
    }

    func testToJSONIncludesStableId() {
        let theme = ConfigurableTheme(
            name: "Any Name",
            id: "stable_theme_id",
            background: .black,
            foreground: .white,
            accent: .blue,
            success: .green,
            warning: .orange,
            error: .red
        )

        let json = theme.toJSON()
        XCTAssertEqual(json["id"] as? String, "stable_theme_id")
    }

    private var requiredColors: [String: String] {
        [
            "background": "#000000",
            "text": "#FFFFFF",
            "accent": "#0000FF",
            "healthy": "#00FF00",
            "warning": "#FFA500",
            "alert": "#FF0000"
        ]
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }

    func toHex() -> String {
        guard let components = NSColor(self).usingColorSpace(.sRGB) else {
            return "#000000"
        }
        let r = Int(components.redComponent * 255)
        let g = Int(components.greenComponent * 255)
        let b = Int(components.blueComponent * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
