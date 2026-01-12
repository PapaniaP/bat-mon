import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @EnvironmentObject var preferencesManager: PreferencesManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Connection status header
            if let keyboard = bluetoothManager.selectedKeyboard {
                KeyboardStatusSection(keyboard: keyboard, connectionState: bluetoothManager.connectionState)
            } else {
                NoKeyboardSection()
            }

            Divider()
                .padding(.vertical, 8)

            // Actions
            ActionsSection(bluetoothManager: bluetoothManager)

            Divider()
                .padding(.vertical, 8)

            // App controls
            AppControlsSection()
        }
        .padding(12)
        .frame(width: 260)
    }
}

// MARK: - Keyboard Status Section

struct KeyboardStatusSection: View {
    let keyboard: ZMKKeyboard
    let connectionState: ConnectionState

    var body: some View {
        VStack(spacing: 12) {
            // Keyboard name with status indicator
            HStack {
                Text(keyboard.effectiveName)
                    .font(.headline)

                Spacer()

                StatusBadge(state: connectionState)
            }

            if connectionState.isConnected {
                // Battery levels - two circular gauges side by side
                HStack(spacing: 20) {
                    BatteryGauge(
                        label: keyboard.leftHalfLabel,
                        battery: keyboard.leftBattery
                    )

                    BatteryGauge(
                        label: keyboard.rightHalfLabel,
                        battery: keyboard.rightBattery
                    )
                }
                .frame(maxWidth: .infinity)

                // Last updated
                if let leftTime = keyboard.leftBattery?.timestamp {
                    Text("Updated \(leftTime.timeAgoDisplay())")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                Text(connectionState.displayText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Battery Gauge (Circular)

struct BatteryGauge: View {
    let label: String
    let battery: BatteryLevel?

    private let size: CGFloat = 56
    private let lineWidth: CGFloat = 5

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)

                // Progress ring
                if let battery = battery {
                    Circle()
                        .trim(from: 0, to: CGFloat(battery.percentage) / 100)
                        .stroke(
                            battery.color,
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    Text("\(battery.percentage)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .monospacedDigit()
                } else {
                    Text("--")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: size, height: size)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let state: ConnectionState

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            if state.isActive {
                ProgressView()
                    .scaleEffect(0.5)
                    .frame(width: 12, height: 12)
            }
        }
    }

    private var statusColor: Color {
        switch state {
        case .connected: return .green
        case .searching, .connecting, .reconnecting: return .orange
        case .disconnected: return .gray
        case .failed: return .red
        }
    }
}

// MARK: - No Keyboard Section

struct NoKeyboardSection: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "keyboard")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("No Keyboard Selected")
                .font(.headline)

            Text("Click 'Scan for Keyboards' to find your ZMK keyboard")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

// MARK: - Actions Section

struct ActionsSection: View {
    @ObservedObject var bluetoothManager: BluetoothManager

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if bluetoothManager.connectionState.isConnected {
                MenuButton(title: "Refresh Now", icon: "arrow.clockwise") {
                    bluetoothManager.refreshBatteryLevels()
                }

                MenuButton(title: "Disconnect", icon: "xmark.circle") {
                    bluetoothManager.disconnect()
                }
            } else if bluetoothManager.isScanning {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.6)
                    Text("Scanning...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 2)

                MenuButton(title: "Stop Scanning", icon: "stop.circle") {
                    bluetoothManager.stopScanning()
                }
            } else {
                MenuButton(title: "Scan for Keyboards", icon: "antenna.radiowaves.left.and.right") {
                    bluetoothManager.startScanning()
                }

                if bluetoothManager.selectedKeyboard != nil {
                    MenuButton(title: "Reconnect", icon: "arrow.triangle.2.circlepath") {
                        bluetoothManager.reconnect()
                    }
                }
            }
        }
    }
}

// MARK: - Menu Button

struct MenuButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .frame(width: 16)
                Text(title)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 2)
    }
}

// MARK: - App Controls Section

struct AppControlsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SettingsButton()

            MenuButton(title: "Quit BatMon", icon: "power") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

struct SettingsButton: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button(action: {
            openSettings()
            // Bring app to front and focus the settings window
            DispatchQueue.main.async {
                NSApp.activate(ignoringOtherApps: true)
                for window in NSApp.windows where window.title == "Settings" || window.identifier?.rawValue == "settings" {
                    window.makeKeyAndOrderFront(nil)
                }
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "gear")
                    .frame(width: 16)
                Text("Settings...")
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 2)
        .keyboardShortcut(",", modifiers: .command)
    }
}

// MARK: - Date Extension

extension Date {
    func timeAgoDisplay() -> String {
        let seconds = Int(-self.timeIntervalSinceNow)

        if seconds < 60 {
            return "just now"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes)m ago"
        } else {
            let hours = seconds / 3600
            return "\(hours)h ago"
        }
    }
}
