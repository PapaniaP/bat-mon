import Foundation

enum ConnectionState: Equatable {
    case disconnected
    case searching
    case connecting
    case connected
    case reconnecting(attempt: Int, maxAttempts: Int)
    case failed(String)

    var displayText: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .searching: return "Searching..."
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .reconnecting(let attempt, let max):
            return "Reconnecting (\(attempt)/\(max))..."
        case .failed(let message):
            return "Failed: \(message)"
        }
    }

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }

    var isActive: Bool {
        switch self {
        case .searching, .connecting, .reconnecting:
            return true
        default:
            return false
        }
    }

    static func == (lhs: ConnectionState, rhs: ConnectionState) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected): return true
        case (.searching, .searching): return true
        case (.connecting, .connecting): return true
        case (.connected, .connected): return true
        case (.reconnecting(let l1, let l2), .reconnecting(let r1, let r2)):
            return l1 == r1 && l2 == r2
        case (.failed(let l), .failed(let r)):
            return l == r
        default: return false
        }
    }
}
