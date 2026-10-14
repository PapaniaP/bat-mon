//
//  TUIWidgetViews.swift
//  BatMonWidget
//
//  TUI-style widget views matching the menu bar TUI design
//

import SwiftUI
import WidgetKit

// MARK: - Small Widget

struct TUISmallWidgetView: View {
    let entry: BatteryEntry
    let half: WidgetHalf
    let theme = WidgetThemeReader.currentTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack {
                Text("bat-mon")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(theme.accent)
                Spacer()
                Text(entry.isConnected ? "●" : "○")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(entry.isConnected ? theme.success : theme.foregroundTertiary)
            }

            if entry.isConnected {
                // Device name
                Text(entry.keyboardName ?? "keyboard")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(theme.foreground)
                    .lineLimit(1)

                Spacer()

                // Battery bars
                VStack(alignment: .leading, spacing: 4) {
                    switch half {
                    case .left:
                        TUIAsciiBar(label: "L", percentage: entry.leftBattery, theme: theme)
                    case .right:
                        TUIAsciiBar(label: "R", percentage: entry.rightBattery, theme: theme)
                    case .both:
                        TUIAsciiBar(label: "L", percentage: entry.leftBattery, theme: theme)
                        TUIAsciiBar(label: "R", percentage: entry.rightBattery, theme: theme)
                    }
                }
            } else {
                Spacer()
                Text("offline")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(theme.foregroundSecondary)
                Spacer()
            }
        }
        .padding(10)
    }
}

// MARK: - Medium Widget

struct TUIMediumWidgetView: View {
    let entry: BatteryEntry
    let theme = WidgetThemeReader.currentTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack {
                Text("bat-mon")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(theme.accent)
                Spacer()
                Text(entry.isConnected ? "●" : "○")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(entry.isConnected ? theme.success : theme.foregroundTertiary)
            }

            // Device name
            HStack(spacing: 4) {
                Text(">")
                    .foregroundStyle(theme.accent)
                Text(entry.keyboardName ?? "no device")
                    .foregroundStyle(theme.foreground)
                    .lineLimit(1)
            }
            .font(.system(size: 11, design: .monospaced))

            Spacer()

            if entry.isConnected {
                // Battery bars
                VStack(alignment: .leading, spacing: 4) {
                    TUIAsciiBar(label: "LEFT ", percentage: entry.leftBattery, theme: theme)
                    TUIAsciiBar(label: "RIGHT", percentage: entry.rightBattery, theme: theme)
                }

                Spacer()

                // Timestamp
                if let time = entry.lastUpdated {
                    Text("~ \(time.widgetTimeAgo())")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(theme.foregroundTertiary)
                }
            } else {
                Text("~ waiting for connection")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(theme.foregroundSecondary)
                Spacer()
            }
        }
        .padding(12)
    }
}

// MARK: - ASCII Battery Bar (matches menu bar TUI style)

struct TUIAsciiBar: View {
    let label: String
    let percentage: Int?
    let theme: WidgetTheme

    private var barColor: Color {
        guard let pct = percentage else { return theme.foregroundTertiary }
        return theme.batteryColor(for: pct)
    }

    private func renderBar(_ pct: Int, length: Int) -> String {
        let filled = Int(Double(pct) / 100.0 * Double(length))
        let empty = length - filled
        return String(repeating: "━", count: filled) + String(repeating: "─", count: empty)
    }

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .foregroundStyle(theme.foregroundSecondary)

            if let pct = percentage {
                Text(renderBar(pct, length: 10))
                    .foregroundStyle(barColor)
                Text(String(format: "%3d%%", pct))
                    .foregroundStyle(theme.foreground)
            } else {
                Text("──────────")
                    .foregroundStyle(theme.foregroundTertiary)
                Text(" --%")
                    .foregroundStyle(theme.foregroundTertiary)
            }
        }
        .font(.system(size: 11, design: .monospaced))
    }
}
