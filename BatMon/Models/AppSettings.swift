import Foundation
import SwiftUI

struct AppSettings: Codable, Equatable {
    // Menu dropdown layout and theme (new system)
    var menuLayout: MenuLayout = .native
    var colorThemeId: String = "system"

    // Legacy: Keep for migration, will be removed in future version
    var menuStyle: MenuStyle? = nil

    // Display settings (for menu bar label)
    var menuBarIcon: MenuBarIcon = .none
    var displayFormat: DisplayFormat = .percentage
    var showPercentSymbol: Bool = true
    var separator: String = " | "

    // Compact mode - icon only, battery info in dropdown
    var compactMode: Bool = false
    var compactIcon: CompactModeIcon = .keyboard
    var customCompactIcon: String = "star.fill"

    // Disconnected icon customization
    var disconnectedIconFillHex: String = "#000000"  // Classic bat silhouette
    var disconnectedIconBorderEnabled: Bool = true
    var disconnectedIconBorderHex: String = "#FF0000"  // Red outline for visibility
    // nil means migrated from older settings; treat as true to keep theme-link as default
    var useThemeDisconnectedIconColors: Bool? = true

    // Experimental display
    var useExperimentalFormat: Bool = false
    var experimentalFormat: ExperimentalFormat = .pipes

    // Behavior settings
    var pollingInterval: TimeInterval = 60
    var launchAtLogin: Bool = true

    // Notification settings
    var enableNotifications: Bool = true
    var lowBatteryThreshold: Int = 20
    var criticalBatteryThreshold: Int = 10

    // Advanced
    var enableDebugLogging: Bool = false
    var autoReconnect: Bool = true
    var maxReconnectAttempts: Int = 10
}

enum MenuBarIcon: String, Codable, CaseIterable, Identifiable {
    case none = "none"
    case keyboard = "keyboard"
    case battery = "battery.100"
    case bolt = "bolt.fill"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "None"
        case .keyboard: return "Keyboard"
        case .battery: return "Battery"
        case .bolt: return "Bolt"
        }
    }

    var sfSymbolName: String? {
        switch self {
        case .none: return nil
        default: return rawValue
        }
    }
}

enum DisplayFormat: String, Codable, CaseIterable, Identifiable {
    case percentage = "percentage"
    case leftOnly = "leftOnly"
    case rightOnly = "rightOnly"
    case lowest = "lowest"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .percentage: return "Both sides"
        case .leftOnly: return "Left only"
        case .rightOnly: return "Right only"
        case .lowest: return "Lowest only"
        }
    }

    var description: String {
        switch self {
        case .percentage: return "Shows both battery levels"
        case .leftOnly: return "Shows only left half"
        case .rightOnly: return "Shows only right half"
        case .lowest: return "Shows whichever is lower"
        }
    }
}

enum CompactModeIcon: String, Codable, CaseIterable, Identifiable {
    case keyboard = "keyboard"
    case keyboardFill = "keyboard.fill"
    case bolt = "bolt.fill"
    case antenna = "antenna.radiowaves.left.and.right"
    case cpu = "cpu"
    case memorychip = "memorychip"
    case custom = "custom"

    var id: String { rawValue }

    var sfSymbolName: String { rawValue }

    var displayName: String {
        switch self {
        case .keyboard: return "Keyboard"
        case .keyboardFill: return "Keyboard (Filled)"
        case .bolt: return "Bolt"
        case .antenna: return "Antenna"
        case .cpu: return "CPU"
        case .memorychip: return "Memory Chip"
        case .custom: return "Custom"
        }
    }
}

enum SeparatorOption: String, CaseIterable, Identifiable {
    case pipe = " | "
    case slash = " / "
    case dot = " · "
    case dash = " - "
    case colon = " : "
    case bullet = " • "
    case arrow = " › "
    case space = "  "
    case none = ""

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pipe: return "Pipe  |"
        case .slash: return "Slash  /"
        case .dot: return "Middle Dot  ·"
        case .dash: return "Dash  -"
        case .colon: return "Colon  :"
        case .bullet: return "Bullet  •"
        case .arrow: return "Arrow  ›"
        case .space: return "Space Only"
        case .none: return "None"
        }
    }
}

enum ExperimentalFormat: String, Codable, CaseIterable, Identifiable {
    case pipes = "pipes"
    case blocks = "blocks"
    case bracketed = "bracketed"
    case arrows = "arrows"
    case slashes = "slashes"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pipes: return "Pipes"
        case .blocks: return "Progress Bars"
        case .bracketed: return "Bracketed"
        case .arrows: return "Arrows"
        case .slashes: return "Slashes"
        }
    }

    var example: String {
        switch self {
        case .pipes: return "|85| |90|"
        case .blocks: return "▰▰▰▰▱ ▰▰▰▱▱"
        case .bracketed: return "[L:85|R:90]"
        case .arrows: return "85 › 90"
        case .slashes: return "85/90"
        }
    }
}

// MARK: - Legacy MenuStyle (for migration only)

enum MenuStyle: String, Codable, CaseIterable, Identifiable {
    case native = "native"
    case rich = "rich"
    case minimal = "minimal"
    case retro = "retro"
    case gruvbox = "gruvbox"
    case tokyoNight = "tokyoNight"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .native: return "Native macOS"
        case .rich: return "Rich & Detailed"
        case .minimal: return "Minimal"
        case .retro: return "Retro Terminal"
        case .gruvbox: return "Gruvbox TUI"
        case .tokyoNight: return "Tokyo Night TUI"
        }
    }

    var description: String {
        switch self {
        case .native: return "Clean glass design matching system style"
        case .rich: return "Card-based with horizontal battery bars"
        case .minimal: return "Ultra-compact, just the essentials"
        case .retro: return "Monospace terminal aesthetic"
        case .gruvbox: return "Warm retro TUI with Gruvbox colors"
        case .tokyoNight: return "Cool modern TUI with Tokyo Night colors"
        }
    }
}

// MARK: - Migration from MenuStyle to Layout + Theme

extension AppSettings {
    /// Migrates from the old MenuStyle system to the new Layout + Theme system
    mutating func migrateFromMenuStyleIfNeeded() {
        guard let oldStyle = menuStyle else { return }

        // Map old style to new layout + theme
        switch oldStyle {
        case .native:
            menuLayout = .native
            colorThemeId = "system"
        case .rich:
            menuLayout = .rich
            colorThemeId = "system"
        case .minimal:
            menuLayout = .minimal
            colorThemeId = "system"
        case .retro:
            menuLayout = .tui
            colorThemeId = "github_dark"
        case .gruvbox:
            menuLayout = .tui
            colorThemeId = "gruvbox"
        case .tokyoNight:
            menuLayout = .tui
            colorThemeId = "tokyoNight"
        }

        // Clear the old style to indicate migration is complete
        menuStyle = nil
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    func toHex() -> String {
        guard let components = NSColor(self).cgColor.components, components.count >= 3 else {
            return "#000000"
        }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
