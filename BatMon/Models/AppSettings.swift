import Foundation

struct AppSettings: Codable, Equatable {
    // Display settings
    var menuBarIcon: MenuBarIcon = .keyboard
    var displayFormat: DisplayFormat = .percentageWithIcon
    var fontStyle: FontStyle = .system
    var useColorCoding: Bool = false
    var separator: String = " | "

    // Behavior settings
    var pollingInterval: TimeInterval = 60
    var launchAtLogin: Bool = true
    var showDockIcon: Bool = false

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
    case keyboard = "keyboard"
    case battery = "battery.100"
    case bolt = "bolt.fill"
    case powerplug = "powerplug.fill"
    case none = "none"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .keyboard: return "Keyboard"
        case .battery: return "Battery"
        case .bolt: return "Lightning Bolt"
        case .powerplug: return "Power Plug"
        case .none: return "No Icon"
        }
    }

    var sfSymbolName: String {
        switch self {
        case .none: return ""
        default: return rawValue
        }
    }
}

enum DisplayFormat: String, Codable, CaseIterable, Identifiable {
    case percentageWithIcon = "85% | 90%"
    case percentageOnly = "85 90"
    case visualBars = "Bars"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .percentageWithIcon: return "Percentage (85% | 90%)"
        case .percentageOnly: return "Numbers only (85 90)"
        case .visualBars: return "Visual bars"
        }
    }
}

enum FontStyle: String, Codable, CaseIterable, Identifiable {
    case system = "System"
    case monospace = "Monospace"

    var id: String { rawValue }
    var displayName: String { rawValue }
}
