import Foundation

struct AppSettings: Codable, Equatable {
    // Display settings
    var menuBarIcon: MenuBarIcon = .none
    var displayFormat: DisplayFormat = .percentage
    var showPercentSymbol: Bool = true
    var separator: String = " | "

    // Compact mode - icon only, battery info in dropdown
    var compactMode: Bool = false
    var compactIcon: CompactModeIcon = .keyboard
    var customCompactIcon: String = "star.fill"

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
