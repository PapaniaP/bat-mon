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

            // Other keyboards (if any discovered)
            if !bluetoothManager.availableKeyboards.isEmpty {
                Divider()
                    .padding(.vertical, 8)

                OtherKeyboardsSection(
                    keyboards: bluetoothManager.availableKeyboards,
                    selectedKeyboard: bluetoothManager.selectedKeyboard,
                    onSelect: { keyboard in
                        bluetoothManager.selectKeyboard(keyboard)
                    }
                )
            }

            Divider()
                .padding(.vertical, 8)

            // App controls
            AppControlsSection()
        }
        .padding(12)
        .frame(width: 280)
    }
}

// MARK: - Keyboard Status Section

struct KeyboardStatusSection: View {
    let keyboard: ZMKKeyboard
    let connectionState: ConnectionState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Keyboard name with status indicator
            HStack {
                Text(keyboard.effectiveName)
                    .font(.headline)

                Spacer()

                StatusBadge(state: connectionState)
            }

            if connectionState.isConnected {
                // Battery levels
                HStack(spacing: 16) {
                    BatteryDisplay(
                        label: keyboard.leftHalfLabel,
                        battery: keyboard.leftBattery
                    )

                    BatteryDisplay(
                        label: keyboard.rightHalfLabel,
                        battery: keyboard.rightBattery
                    )
                }

                // Last updated
                if let leftTime = keyboard.leftBattery?.timestamp {
                    Text("Updated \(leftTime.timeAgoDisplay())")
                        .font(.caption)
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

// MARK: - Battery Display

struct BatteryDisplay: View {
    let label: String
    let battery: BatteryLevel?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 6) {
                if let battery = battery {
                    Image(systemName: battery.sfSymbolName)
                        .foregroundColor(battery.color)

                    Text("\(battery.percentage)%")
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.medium)
                        .monospacedDigit()
                } else {
                    Image(systemName: "battery.0")
                        .foregroundColor(.gray)

                    Text("--")
                        .font(.system(.title3, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        VStack(alignment: .leading, spacing: 4) {
            // Show Bluetooth state
            HStack {
                Circle()
                    .fill(bluetoothStateColor)
                    .frame(width: 8, height: 8)
                Text("Bluetooth: \(bluetoothStateText)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 4)

            if bluetoothManager.connectionState.isConnected {
                Button(action: { bluetoothManager.refreshBatteryLevels() }) {
                    Label("Refresh Now", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.plain)

                Button(action: { bluetoothManager.disconnect() }) {
                    Label("Disconnect", systemImage: "xmark.circle")
                }
                .buttonStyle(.plain)
            } else if bluetoothManager.isScanning {
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Scanning...")
                        .font(.caption)
                }

                Button(action: { bluetoothManager.stopScanning() }) {
                    Label("Stop Scanning", systemImage: "stop.circle")
                }
                .buttonStyle(.plain)
            } else {
                Button(action: { bluetoothManager.startScanning() }) {
                    Label("Scan for Keyboards", systemImage: "antenna.radiowaves.left.and.right")
                }
                .buttonStyle(.plain)

                if bluetoothManager.selectedKeyboard != nil {
                    Button(action: { bluetoothManager.reconnect() }) {
                        Label("Reconnect", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var bluetoothStateColor: Color {
        switch bluetoothManager.bluetoothState {
        case .poweredOn: return .green
        case .poweredOff: return .red
        case .unauthorized: return .orange
        default: return .gray
        }
    }

    private var bluetoothStateText: String {
        switch bluetoothManager.bluetoothState {
        case .poweredOn: return "On"
        case .poweredOff: return "Off"
        case .unauthorized: return "Unauthorized"
        case .unsupported: return "Unsupported"
        case .resetting: return "Resetting"
        case .unknown: return "Unknown"
        @unknown default: return "Unknown"
        }
    }
}

// MARK: - Other Keyboards Section

struct OtherKeyboardsSection: View {
    let keyboards: [ZMKKeyboard]
    let selectedKeyboard: ZMKKeyboard?
    let onSelect: (ZMKKeyboard) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Available Keyboards")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(keyboards) { keyboard in
                Button(action: { onSelect(keyboard) }) {
                    HStack {
                        Image(systemName: "keyboard")
                        Text(keyboard.name)
                        Spacer()
                        if keyboard.id == selectedKeyboard?.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - App Controls Section

struct AppControlsSection: View {
    var body: some View {
        VStack(spacing: 4) {
            Button(action: openSettingsWindow) {
                Label("Settings...", systemImage: "gear")
            }
            .buttonStyle(.plain)
            .keyboardShortcut(",", modifiers: .command)

            Button(action: { NSApplication.shared.terminate(nil) }) {
                Label("Quit BatMon", systemImage: "power")
            }
            .buttonStyle(.plain)
            .keyboardShortcut("q", modifiers: .command)
        }
    }

    private func openSettingsWindow() {
        if #available(macOS 14.0, *) {
            // Use the newer API on macOS 14+
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            // Fallback for macOS 13
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
        NSApp.activate(ignoringOtherApps: true)
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
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else {
            let hours = seconds / 3600
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        }
    }
}
