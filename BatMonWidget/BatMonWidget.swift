//
//  BatMonWidget.swift
//  BatMonWidget
//
//  Main widget definitions for BatMon
//  Provides Rich and TUI style widgets in Small and Medium sizes
//

import WidgetKit
import SwiftUI

// MARK: - Rich Style Widget

struct RichBatteryWidget: Widget {
    let kind: String = "RichBatteryWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SmallWidgetConfigurationIntent.self,
            provider: ConfigurableBatteryProvider()
        ) { entry in
            RichWidgetEntryView(
                entry: entry.batteryEntry,
                half: entry.displayHalf
            )
            .containerBackground(for: .widget) {
                WidgetThemeReader.currentTheme.background
            }
        }
        .configurationDisplayName("Rich Style")
        .description("Modern battery display with visual bars")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

struct RichWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: BatteryEntry
    let half: WidgetHalf

    var body: some View {
        switch family {
        case .systemSmall:
            RichSmallWidgetView(entry: entry, half: half)
        default:
            RichMediumWidgetView(entry: entry)
        }
    }
}

// MARK: - TUI Style Widget

struct TUIBatteryWidget: Widget {
    let kind: String = "TUIBatteryWidget2"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SmallWidgetConfigurationIntent.self,
            provider: ConfigurableBatteryProvider()
        ) { entry in
            TUIWidgetEntryView(
                entry: entry.batteryEntry,
                half: entry.displayHalf
            )
            .containerBackground(for: .widget) {
                WidgetThemeReader.currentTheme.background
            }
        }
        .configurationDisplayName("TUI Style")
        .description("Terminal-style display with bordered bars")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

struct TUIWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: BatteryEntry
    let half: WidgetHalf

    var body: some View {
        switch family {
        case .systemSmall:
            TUISmallWidgetView(entry: entry, half: half)
        default:
            TUIMediumWidgetView(entry: entry)
        }
    }
}

// MARK: - Previews

#Preview("Rich Small", as: .systemSmall) {
    RichBatteryWidget()
} timeline: {
    ConfiguredBatteryEntry.preview()
}

#Preview("Rich Medium", as: .systemMedium) {
    RichBatteryWidget()
} timeline: {
    ConfiguredBatteryEntry.preview()
}

#Preview("TUI Small", as: .systemSmall) {
    TUIBatteryWidget()
} timeline: {
    ConfiguredBatteryEntry.preview()
}

#Preview("TUI Medium", as: .systemMedium) {
    TUIBatteryWidget()
} timeline: {
    ConfiguredBatteryEntry.preview()
}

#Preview("Disconnected", as: .systemMedium) {
    RichBatteryWidget()
} timeline: {
    ConfiguredBatteryEntry.disconnected()
}
