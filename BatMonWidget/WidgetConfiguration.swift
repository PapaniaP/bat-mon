//
//  WidgetConfiguration.swift
//  BatMonWidget
//
//  AppIntent configuration for widget customization
//  Allows users to choose which battery half to display in small widgets
//

import AppIntents
import WidgetKit

// MARK: - Configuration Intent

/// Configuration intent for widgets
/// Users can choose to show Left, Right, or Both battery halves (for small widgets)
struct SmallWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configure Widget"
    static var description = IntentDescription("Choose which battery to display")

    @Parameter(title: "Display", default: .both)
    var displayHalf: WidgetHalfOption
}

/// Options for which half to display
enum WidgetHalfOption: String, AppEnum {
    case left
    case right
    case both

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Battery Display"
    }

    static var caseDisplayRepresentations: [WidgetHalfOption: DisplayRepresentation] {
        [
            .left: DisplayRepresentation(title: "Left Only", subtitle: "Show only left battery"),
            .right: DisplayRepresentation(title: "Right Only", subtitle: "Show only right battery"),
            .both: DisplayRepresentation(title: "Both", subtitle: "Show both batteries")
        ]
    }

    /// Convert to internal WidgetHalf type
    var toWidgetHalf: WidgetHalf {
        switch self {
        case .left: return .left
        case .right: return .right
        case .both: return .both
        }
    }
}

// MARK: - Combined Timeline Entry

/// Timeline entry that combines battery data with widget configuration
struct ConfiguredBatteryEntry: TimelineEntry {
    let date: Date
    let batteryEntry: BatteryEntry
    let displayHalf: WidgetHalf

    /// Preview entry for widget gallery
    static func preview() -> ConfiguredBatteryEntry {
        ConfiguredBatteryEntry(
            date: Date(),
            batteryEntry: .placeholder,
            displayHalf: .both
        )
    }

    /// Disconnected state preview
    static func disconnected() -> ConfiguredBatteryEntry {
        ConfiguredBatteryEntry(
            date: Date(),
            batteryEntry: .empty,
            displayHalf: .both
        )
    }
}

// MARK: - Configurable Timeline Provider

/// Timeline provider that supports configuration for widgets
struct ConfigurableBatteryProvider: AppIntentTimelineProvider {
    typealias Entry = ConfiguredBatteryEntry
    typealias Intent = SmallWidgetConfigurationIntent

    private let sharedDefaults = UserDefaults(suiteName: "group.com.paolo.bat-mon")

    func placeholder(in context: Context) -> ConfiguredBatteryEntry {
        .preview()
    }

    func snapshot(for configuration: SmallWidgetConfigurationIntent, in context: Context) async -> ConfiguredBatteryEntry {
        if context.isPreview {
            return .preview()
        }
        return ConfiguredBatteryEntry(
            date: Date(),
            batteryEntry: readCurrentBatteryEntry(),
            displayHalf: configuration.displayHalf.toWidgetHalf
        )
    }

    func timeline(for configuration: SmallWidgetConfigurationIntent, in context: Context) async -> Timeline<ConfiguredBatteryEntry> {
        let batteryEntry = readCurrentBatteryEntry()
        let entry = ConfiguredBatteryEntry(
            date: Date(),
            batteryEntry: batteryEntry,
            displayHalf: configuration.displayHalf.toWidgetHalf
        )

        // Refresh after 15 minutes if connected, 1 hour if disconnected
        // Main app triggers immediate refresh via WidgetCenter.reloadAllTimelines()
        let refreshInterval: TimeInterval = batteryEntry.isConnected ? 15 * 60 : 60 * 60
        let nextUpdate = Date().addingTimeInterval(refreshInterval)

        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func readCurrentBatteryEntry() -> BatteryEntry {
        guard let defaults = sharedDefaults else {
            return .empty
        }

        let keyboardName = defaults.string(forKey: "widgetKeyboardName")
        let isConnected = defaults.bool(forKey: "widgetIsConnected")
        let leftBattery = defaults.object(forKey: "widgetLeftBattery") as? Int
        let rightBattery = defaults.object(forKey: "widgetRightBattery") as? Int
        let lastUpdated = defaults.object(forKey: "widgetLastUpdated") as? Date

        return BatteryEntry(
            date: Date(),
            keyboardName: keyboardName,
            leftBattery: leftBattery,
            rightBattery: rightBattery,
            isConnected: isConnected,
            lastUpdated: lastUpdated
        )
    }
}
