//
//  BatteryEntry.swift
//  BatMonWidget
//
//  TimelineEntry model for widget data
//

import WidgetKit
import Foundation

/// Which half of the keyboard to display in small widgets
enum WidgetHalf: String, CaseIterable {
    case left = "left"
    case right = "right"
    case both = "both"

    var displayName: String {
        switch self {
        case .left: return "Left"
        case .right: return "Right"
        case .both: return "Both"
        }
    }
}

/// TimelineEntry containing battery data for widgets
struct BatteryEntry: TimelineEntry {
    let date: Date
    let keyboardName: String?
    let leftBattery: Int?
    let rightBattery: Int?
    let isConnected: Bool
    let lastUpdated: Date?

    /// Creates a placeholder entry for widget previews
    static var placeholder: BatteryEntry {
        BatteryEntry(
            date: Date(),
            keyboardName: "ZMK Keyboard",
            leftBattery: 85,
            rightBattery: 92,
            isConnected: true,
            lastUpdated: Date()
        )
    }

    /// Creates an empty entry for when no data is available
    static var empty: BatteryEntry {
        BatteryEntry(
            date: Date(),
            keyboardName: nil,
            leftBattery: nil,
            rightBattery: nil,
            isConnected: false,
            lastUpdated: nil
        )
    }
}
