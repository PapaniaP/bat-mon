import SwiftUI

struct BatteryLevel: Codable, Equatable {
    let percentage: Int
    let timestamp: Date

    var color: Color {
        switch percentage {
        case 0...10:  return .red
        case 11...20: return .orange
        case 21...50: return .yellow
        case 51...100: return .green
        default: return .gray
        }
    }

    var sfSymbolName: String {
        switch percentage {
        case 0...10:   return "battery.0"
        case 11...25:  return "battery.25"
        case 26...50:  return "battery.50"
        case 51...75:  return "battery.75"
        case 76...100: return "battery.100"
        default: return "battery.0"
        }
    }
}
