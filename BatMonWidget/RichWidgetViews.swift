//
//  RichWidgetViews.swift
//  BatMonWidget
//
//  Rich-style widget views (Small, Medium)
//  Matches the Rich menu bar style with clean, modern design
//

import SwiftUI
import WidgetKit

// MARK: - Small Widget (141×141)

struct RichSmallWidgetView: View {
    let entry: BatteryEntry
    let half: WidgetHalf
    let theme = WidgetThemeReader.currentTheme

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(entry.keyboardName ?? "BatMon")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(theme.foregroundSecondary)
                    .lineLimit(1)
                Spacer()
                Circle()
                    .fill(entry.isConnected ? theme.success : theme.foregroundTertiary)
                    .frame(width: 6, height: 6)
            }

            Spacer()

            // Battery display based on configured half
            if entry.isConnected {
                batteryContent
            } else {
                disconnectedContent
            }

            Spacer()
        }
        .padding(8)
    }

    @ViewBuilder
    private var batteryContent: some View {
        switch half {
        case .left:
            RichBatteryPill(label: "L", percentage: entry.leftBattery, theme: theme)
        case .right:
            RichBatteryPill(label: "R", percentage: entry.rightBattery, theme: theme)
        case .both:
            HStack(spacing: 8) {
                RichBatteryPill(label: "L", percentage: entry.leftBattery, theme: theme)
                RichBatteryPill(label: "R", percentage: entry.rightBattery, theme: theme)
            }
        }
    }

    @ViewBuilder
    private var disconnectedContent: some View {
        VStack(spacing: 4) {
            Image(systemName: "keyboard.badge.ellipsis")
                .font(.system(size: 24))
                .foregroundStyle(theme.foregroundTertiary)
            Text("Disconnected")
                .font(.system(size: 10))
                .foregroundStyle(theme.foregroundSecondary)
        }
    }
}

// MARK: - Medium Widget (292×141)

struct RichMediumWidgetView: View {
    let entry: BatteryEntry
    let theme = WidgetThemeReader.currentTheme

    var body: some View {
        HStack(spacing: 16) {
            // Left side: Name and status
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "keyboard.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(theme.foregroundSecondary)
                    Text(entry.keyboardName ?? "BatMon")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(theme.foreground)
                        .lineLimit(1)
                }

                RichStatusBadge(isConnected: entry.isConnected, theme: theme)

                Spacer()

                if let time = entry.lastUpdated, entry.isConnected {
                    Text(time.widgetTimeAgo())
                        .font(.system(size: 10))
                        .foregroundStyle(theme.foregroundTertiary)
                }
            }

            Spacer()

            // Right side: Battery bars or disconnected state
            if entry.isConnected {
                VStack(spacing: 10) {
                    RichHorizontalBar(label: "Left", percentage: entry.leftBattery, theme: theme)
                    RichHorizontalBar(label: "Right", percentage: entry.rightBattery, theme: theme)
                }
                .frame(width: 140)
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "keyboard.badge.ellipsis")
                        .font(.system(size: 28))
                        .foregroundStyle(theme.foregroundTertiary)
                    Text("Open BatMon")
                        .font(.system(size: 10))
                        .foregroundStyle(theme.foregroundSecondary)
                }
            }
        }
        .padding(10)
    }
}

// MARK: - Shared Components

/// Battery pill for small widgets
struct RichBatteryPill: View {
    let label: String
    let percentage: Int?
    let theme: WidgetTheme

    private var batteryColor: Color {
        guard let pct = percentage else { return theme.foregroundTertiary }
        return theme.batteryColor(for: pct)
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(theme.foregroundSecondary)

            Text(percentage.map { "\($0)" } ?? "--")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(batteryColor)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text("%")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(theme.foregroundSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(theme.foreground.opacity(0.05))
        .cornerRadius(10)
    }
}

/// Horizontal battery bar for medium widget
struct RichHorizontalBar: View {
    let label: String
    let percentage: Int?
    let theme: WidgetTheme

    private var batteryColor: Color {
        guard let pct = percentage else { return theme.foregroundTertiary }
        return theme.batteryColor(for: pct)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundStyle(theme.foregroundSecondary)
                Spacer()
                Text(percentage.map { "\($0)%" } ?? "--%")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(theme.foreground)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(theme.foreground.opacity(0.1))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(batteryColor.gradient)
                        .frame(width: geo.size.width * CGFloat(percentage ?? 0) / 100)
                }
            }
            .frame(height: 8)
        }
    }
}

/// Status badge showing connection state
struct RichStatusBadge: View {
    let isConnected: Bool
    let theme: WidgetTheme

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isConnected ? theme.success : theme.foregroundTertiary)
                .frame(width: 6, height: 6)
            Text(isConnected ? "Connected" : "Offline")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(theme.foregroundSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background((isConnected ? theme.success : theme.foregroundTertiary).opacity(0.15))
        .cornerRadius(10)
    }
}
