import Foundation

/// Defines the structural layout of the menu dropdown
enum MenuLayout: String, Codable, CaseIterable, Identifiable {
    case native = "native"
    case rich = "rich"
    case minimal = "minimal"
    case tui = "tui"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .native: return "Native macOS"
        case .rich: return "Rich & Detailed"
        case .minimal: return "Minimal"
        case .tui: return "Terminal UI"
        }
    }

    var description: String {
        switch self {
        case .native: return "Clean glass design matching system style"
        case .rich: return "Card-based with horizontal battery bars"
        case .minimal: return "Ultra-compact, just the essentials"
        case .tui: return "Monospace terminal aesthetic with full theming"
        }
    }

    /// Whether this layout uses the full theme palette (background, text, etc.)
    /// If false, only semantic colors (battery, status) are themed
    var usesFullThemePalette: Bool {
        self == .tui
    }
}
