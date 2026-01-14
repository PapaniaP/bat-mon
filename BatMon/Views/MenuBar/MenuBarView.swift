import SwiftUI
import AppKit

// MARK: - Bluetooth Settings Helper

func openBluetoothSettings() {
    // Open Privacy & Security > Bluetooth where app permissions are managed
    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Bluetooth") {
        NSWorkspace.shared.open(url)
    }
}

struct MenuBarView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @EnvironmentObject var preferencesManager: PreferencesManager

    private var currentTheme: any ColorTheme {
        ThemeRegistry.shared.theme(for: preferencesManager.settings.colorThemeId)
    }

    var body: some View {
        Group {
            switch preferencesManager.settings.menuLayout {
            case .native:
                NativeMenuBarView()
            case .rich:
                RichMenuBarView()
            case .minimal:
                MinimalMenuBarView()
            case .tui:
                TUIMenuBarView()
            }
        }
        .environmentObject(bluetoothManager)
        .environmentObject(preferencesManager)
        .environment(\.colorTheme, currentTheme)
    }
}

// MARK: - =====================================================
// MARK: - NATIVE macOS STYLE
// MARK: - =====================================================

struct NativeMenuBarView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @Environment(\.colorTheme) var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Status section
            if let keyboard = bluetoothManager.selectedKeyboard {
                NativeKeyboardStatus(keyboard: keyboard, connectionState: bluetoothManager.connectionState)
            } else {
                NativeNoKeyboardView()
            }

            NativeDivider()

            // Actions
            NativeActionsSection(bluetoothManager: bluetoothManager)

            NativeDivider()

            // App controls
            NativeControlsSection()
        }
        .padding(12)
        .frame(width: 280)
        .background(theme.background)
    }
}

// MARK: - Native Keyboard Status

struct NativeKeyboardStatus: View {
    let keyboard: ZMKKeyboard
    let connectionState: ConnectionState
    @Environment(\.colorTheme) var theme

    var body: some View {
        VStack(spacing: 16) {
            // Header row
            HStack {
                Image(systemName: "keyboard.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(theme.foregroundSecondary)

                Text(keyboard.effectiveName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.foreground)

                Spacer()

                NativeStatusIndicator(state: connectionState)
            }

            if connectionState.isConnected {
                // Battery displays
                HStack(spacing: 24) {
                    NativeBatteryDisplay(
                        label: keyboard.leftHalfLabel,
                        percentage: keyboard.leftBattery?.percentage
                    )

                    NativeBatteryDisplay(
                        label: keyboard.rightHalfLabel,
                        percentage: keyboard.rightBattery?.percentage
                    )
                }
                .frame(maxWidth: .infinity)

                // Last updated
                if let time = keyboard.leftBattery?.timestamp ?? keyboard.rightBattery?.timestamp {
                    Text("Updated \(time.timeAgoDisplay())")
                        .font(.system(size: 11))
                        .foregroundStyle(theme.foregroundTertiary)
                }
            } else {
                VStack(spacing: 8) {
                    Text(connectionState.displayText)
                        .font(.system(size: 12))
                        .foregroundStyle(theme.foregroundSecondary)

                    if connectionState.isBluetoothUnavailable {
                        Button {
                            openBluetoothSettings()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "gear.badge")
                                    .font(.system(size: 11))
                                Text("Allow Bluetooth")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(theme.accent)
                            .foregroundStyle(theme.background)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}

// MARK: - Native Battery Display

struct NativeBatteryDisplay: View {
    let label: String
    let percentage: Int?
    @Environment(\.colorTheme) var theme

    private var batteryColor: Color {
        guard let pct = percentage else { return theme.foregroundTertiary }
        return theme.batteryColor(for: pct)
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Background arc
                Circle()
                    .stroke(theme.foregroundTertiary.opacity(0.3), lineWidth: 4)

                // Progress arc
                Circle()
                    .trim(from: 0, to: CGFloat(percentage ?? 0) / 100)
                    .stroke(
                        batteryColor,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                // Percentage text
                Text(percentage.map { "\($0)" } ?? "--")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(theme.foreground)
            }
            .frame(width: 56, height: 56)

            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(theme.foregroundSecondary)
        }
    }
}

// MARK: - Native Status Indicator

struct NativeStatusIndicator: View {
    let state: ConnectionState
    @Environment(\.colorTheme) var theme

    private var color: Color {
        switch state {
        case .connected: return theme.success
        case .searching, .connecting, .reconnecting: return theme.warning
        case .disconnected: return theme.foregroundTertiary
        case .failed: return theme.error
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            if state.isActive {
                ProgressView()
                    .scaleEffect(0.5)
                    .frame(width: 12, height: 12)
            }
        }
    }
}

// MARK: - Native No Keyboard View

struct NativeNoKeyboardView: View {
    @Environment(\.colorTheme) var theme

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "keyboard.badge.ellipsis")
                .font(.system(size: 32))
                .foregroundStyle(theme.foregroundTertiary)

            Text("No Keyboard")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.foreground)

            Text("Scan to find your ZMK keyboard")
                .font(.system(size: 11))
                .foregroundStyle(theme.foregroundSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

// MARK: - Native Actions Section

struct NativeActionsSection: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @Environment(\.colorTheme) var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if bluetoothManager.connectionState.isConnected {
                NativeMenuRow(title: "Refresh", icon: "arrow.clockwise") {
                    bluetoothManager.refreshBatteryLevels()
                }

                NativeMenuRow(title: "Disconnect", icon: "xmark.circle") {
                    bluetoothManager.disconnect()
                }
            } else {
                if bluetoothManager.isScanning {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.6)
                        Text("Scanning...")
                            .font(.system(size: 13))
                            .foregroundStyle(theme.foregroundSecondary)
                    }
                    .padding(.vertical, 6)

                    NativeMenuRow(title: "Stop", icon: "stop.fill") {
                        bluetoothManager.stopScanning()
                    }
                } else {
                    NativeMenuRow(title: "Scan for Keyboards", icon: "antenna.radiowaves.left.and.right") {
                        bluetoothManager.startScanning()
                    }

                    if bluetoothManager.selectedKeyboard != nil {
                        NativeMenuRow(title: "Reconnect", icon: "arrow.triangle.2.circlepath") {
                            bluetoothManager.reconnect()
                        }
                    }
                }

                // Available keyboards
                if !bluetoothManager.availableKeyboards.isEmpty {
                    NativeDivider()

                    Text("AVAILABLE")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(theme.foregroundTertiary)
                        .padding(.top, 4)
                        .padding(.bottom, 2)

                    ForEach(bluetoothManager.availableKeyboards) { keyboard in
                        NativeKeyboardRow(
                            keyboard: keyboard,
                            isSelected: bluetoothManager.selectedKeyboard?.peripheralIdentifier == keyboard.peripheralIdentifier
                        ) {
                            bluetoothManager.selectKeyboard(keyboard)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Native Menu Row

struct NativeMenuRow: View {
    let title: String
    let icon: String
    let action: () -> Void
    @State private var isHovered = false
    @Environment(\.colorTheme) var theme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .frame(width: 16)
                    .foregroundStyle(theme.foregroundSecondary)

                Text(title)
                    .font(.system(size: 13))
                    .foregroundStyle(theme.foreground)

                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(isHovered ? theme.foreground.opacity(0.1) : Color.clear)
            .cornerRadius(6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Native Keyboard Row

struct NativeKeyboardRow: View {
    let keyboard: ZMKKeyboard
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false
    @Environment(\.colorTheme) var theme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "keyboard")
                    .font(.system(size: 12))
                    .frame(width: 16)
                    .foregroundStyle(isSelected ? theme.accent : theme.foregroundSecondary)

                Text(keyboard.name)
                    .font(.system(size: 13))
                    .foregroundStyle(isSelected ? theme.accent : theme.foreground)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(theme.accent)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(isSelected ? theme.accent.opacity(0.1) : (isHovered ? theme.foreground.opacity(0.1) : Color.clear))
            .cornerRadius(6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Native Controls Section

struct NativeControlsSection: View {
    @Environment(\.openSettings) private var openSettings
    @Environment(\.colorTheme) var theme
    @State private var isSettingsHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Button(action: {
                openSettings()
                DispatchQueue.main.async {
                    NSApp.activate(ignoringOtherApps: true)
                }
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "gear")
                        .font(.system(size: 12))
                        .frame(width: 16)
                        .foregroundStyle(theme.foregroundSecondary)

                    Text("Settings...")
                        .font(.system(size: 13))
                        .foregroundStyle(theme.foreground)

                    Spacer()

                    Text("⌘,")
                        .font(.system(size: 11))
                        .foregroundStyle(theme.foregroundTertiary)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(isSettingsHovered ? theme.foreground.opacity(0.1) : Color.clear)
                .cornerRadius(6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { isSettingsHovered = $0 }
            .keyboardShortcut(",", modifiers: .command)

            NativeMenuRow(title: "Quit BatMon", icon: "power") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

// MARK: - Native Divider

struct NativeDivider: View {
    @Environment(\.colorTheme) var theme

    var body: some View {
        Rectangle()
            .fill(theme.divider)
            .frame(height: 1)
            .padding(.vertical, 8)
    }
}

// MARK: - =====================================================
// MARK: - RICH STYLE
// MARK: - =====================================================

struct RichMenuBarView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @Environment(\.colorTheme) var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Status card
            if let keyboard = bluetoothManager.selectedKeyboard {
                RichStatusCard(keyboard: keyboard, connectionState: bluetoothManager.connectionState)
            } else {
                RichNoKeyboardCard()
            }

            // Actions
            RichActionsSection(bluetoothManager: bluetoothManager)

            Rectangle()
                .fill(theme.divider)
                .frame(height: 1)

            // Controls
            RichControlsSection()
        }
        .padding(14)
        .frame(width: 300)
        .background(theme.background)
    }
}

// MARK: - Rich Status Card

struct RichStatusCard: View {
    let keyboard: ZMKKeyboard
    let connectionState: ConnectionState
    @Environment(\.colorTheme) var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "keyboard.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(theme.foregroundSecondary)

                Text(keyboard.effectiveName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.foreground)

                Spacer()

                RichStatusBadge(state: connectionState)
            }

            if connectionState.isConnected {
                // Battery bars
                VStack(spacing: 8) {
                    RichBatteryBar(
                        label: keyboard.leftHalfLabel,
                        percentage: keyboard.leftBattery?.percentage
                    )

                    RichBatteryBar(
                        label: keyboard.rightHalfLabel,
                        percentage: keyboard.rightBattery?.percentage
                    )
                }

                // Timestamp
                if let time = keyboard.leftBattery?.timestamp ?? keyboard.rightBattery?.timestamp {
                    HStack {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text("Updated \(time.timeAgoDisplay())")
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(theme.foregroundSecondary)
                }
            } else {
                VStack(spacing: 8) {
                    HStack {
                        if connectionState.isActive {
                            ProgressView()
                                .scaleEffect(0.6)
                        }
                        Text(connectionState.displayText)
                            .font(.system(size: 12))
                            .foregroundStyle(theme.foregroundSecondary)
                    }

                    if connectionState.isBluetoothUnavailable {
                        Button {
                            openBluetoothSettings()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "gear.badge")
                                    .font(.system(size: 11))
                                Text("Allow Bluetooth")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(theme.accent)
                            .foregroundStyle(theme.background)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding(12)
        .background(theme.backgroundSecondary)
        .cornerRadius(10)
    }
}

// MARK: - Rich Battery Bar

struct RichBatteryBar: View {
    let label: String
    let percentage: Int?
    @Environment(\.colorTheme) var theme

    private var batteryColor: Color {
        guard let pct = percentage else { return theme.foregroundTertiary }
        return theme.batteryColor(for: pct)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(theme.foregroundSecondary)

                Spacer()

                Text(percentage.map { "\($0)%" } ?? "--%")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(theme.foreground)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.foregroundTertiary.opacity(0.3))

                    // Fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(batteryColor.gradient)
                        .frame(width: geo.size.width * CGFloat(percentage ?? 0) / 100)
                }
            }
            .frame(height: 10)
        }
    }
}

// MARK: - Rich Status Badge

struct RichStatusBadge: View {
    let state: ConnectionState
    @Environment(\.colorTheme) var theme

    private var color: Color {
        switch state {
        case .connected: return theme.success
        case .searching, .connecting, .reconnecting: return theme.warning
        case .disconnected: return theme.foregroundTertiary
        case .failed: return theme.error
        }
    }

    private var text: String {
        switch state {
        case .connected: return "Connected"
        case .searching: return "Searching"
        case .connecting: return "Connecting"
        case .reconnecting: return "Reconnecting"
        case .disconnected: return "Offline"
        case .failed: return "Failed"
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)

            Text(text)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(theme.foregroundSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .cornerRadius(12)
    }
}

// MARK: - Rich No Keyboard Card

struct RichNoKeyboardCard: View {
    @Environment(\.colorTheme) var theme

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "keyboard.badge.ellipsis")
                .font(.system(size: 36))
                .foregroundStyle(theme.foregroundTertiary)

            VStack(spacing: 4) {
                Text("No Keyboard")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.foreground)

                Text("Scan to discover nearby devices")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.foregroundSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(theme.backgroundSecondary)
        .cornerRadius(10)
    }
}

// MARK: - Rich Actions Section

struct RichActionsSection: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @Environment(\.colorTheme) var theme

    var body: some View {
        VStack(spacing: 8) {
            if bluetoothManager.connectionState.isConnected {
                HStack(spacing: 8) {
                    RichPillButton(title: "Refresh", icon: "arrow.clockwise") {
                        bluetoothManager.refreshBatteryLevels()
                    }

                    RichPillButton(title: "Disconnect", icon: "xmark.circle", style: .secondary) {
                        bluetoothManager.disconnect()
                    }
                }
            } else {
                if bluetoothManager.isScanning {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Scanning for keyboards...")
                            .font(.system(size: 12))
                            .foregroundStyle(theme.foregroundSecondary)
                        Spacer()
                    }
                    .padding(.vertical, 4)

                    RichPillButton(title: "Stop Scanning", icon: "stop.fill", style: .secondary) {
                        bluetoothManager.stopScanning()
                    }
                } else {
                    RichPillButton(title: "Scan for Keyboards", icon: "antenna.radiowaves.left.and.right") {
                        bluetoothManager.startScanning()
                    }

                    if bluetoothManager.selectedKeyboard != nil {
                        RichPillButton(title: "Reconnect", icon: "arrow.triangle.2.circlepath", style: .secondary) {
                            bluetoothManager.reconnect()
                        }
                    }
                }

                // Available keyboards
                if !bluetoothManager.availableKeyboards.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Available Keyboards")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(theme.foregroundTertiary)
                            .padding(.top, 4)

                        ForEach(bluetoothManager.availableKeyboards) { keyboard in
                            RichKeyboardRow(
                                keyboard: keyboard,
                                isSelected: bluetoothManager.selectedKeyboard?.peripheralIdentifier == keyboard.peripheralIdentifier
                            ) {
                                bluetoothManager.selectKeyboard(keyboard)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Rich Pill Button

struct RichPillButton: View {
    let title: String
    let icon: String
    var style: ButtonStyle = .primary
    let action: () -> Void
    @State private var isHovered = false
    @Environment(\.colorTheme) var theme

    enum ButtonStyle {
        case primary, secondary
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return isHovered ? theme.accent.opacity(0.8) : theme.accent
        case .secondary:
            return isHovered ? theme.foreground.opacity(0.15) : theme.foreground.opacity(0.1)
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(backgroundColor)
            .foregroundStyle(style == .primary ? theme.background : theme.foreground)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Rich Keyboard Row

struct RichKeyboardRow: View {
    let keyboard: ZMKKeyboard
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false
    @Environment(\.colorTheme) var theme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "keyboard")
                    .font(.system(size: 12))
                    .foregroundStyle(isSelected ? theme.accent : theme.foregroundSecondary)

                Text(keyboard.name)
                    .font(.system(size: 13))
                    .foregroundStyle(theme.foreground)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(theme.accent)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(isSelected ? theme.accent.opacity(0.1) : (isHovered ? theme.foreground.opacity(0.08) : theme.foreground.opacity(0.03)))
            .cornerRadius(8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Rich Controls Section

struct RichControlsSection: View {
    @Environment(\.openSettings) private var openSettings
    @Environment(\.colorTheme) var theme
    @State private var isSettingsHovered = false
    @State private var isQuitHovered = false

    var body: some View {
        HStack(spacing: 0) {
            Button(action: {
                openSettings()
                DispatchQueue.main.async {
                    NSApp.activate(ignoringOtherApps: true)
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "gear")
                        .font(.system(size: 11))
                    Text("Settings")
                        .font(.system(size: 12))
                }
                .foregroundStyle(isSettingsHovered ? theme.foreground : theme.foregroundSecondary)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(isSettingsHovered ? theme.foreground.opacity(0.1) : Color.clear)
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .onHover { isSettingsHovered = $0 }
            .keyboardShortcut(",", modifiers: .command)

            Spacer()

            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "power")
                        .font(.system(size: 11))
                    Text("Quit")
                        .font(.system(size: 12))
                }
                .foregroundStyle(isQuitHovered ? theme.foreground : theme.foregroundSecondary)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(isQuitHovered ? theme.foreground.opacity(0.1) : Color.clear)
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .onHover { isQuitHovered = $0 }
        }
        .padding(.top, 4)
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

// MARK: - =====================================================
// MARK: - MINIMAL STYLE
// MARK: - =====================================================

struct MinimalMenuBarView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @Environment(\.colorTheme) var theme

    var body: some View {
        VStack(spacing: 0) {
            // Battery display - ultra compact
            if let keyboard = bluetoothManager.selectedKeyboard,
               bluetoothManager.connectionState.isConnected {
                HStack(spacing: 16) {
                    MinimalBattery(label: "L", percentage: keyboard.leftBattery?.percentage)
                    MinimalBattery(label: "R", percentage: keyboard.rightBattery?.percentage)
                }
                .padding(.vertical, 16)
            } else {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(bluetoothManager.connectionState.isActive ? theme.warning : theme.foregroundTertiary)
                            .frame(width: 8, height: 8)
                        Text(bluetoothManager.connectionState.isBluetoothUnavailable
                             ? "Bluetooth Unavailable"
                             : (bluetoothManager.selectedKeyboard?.effectiveName ?? "No Keyboard"))
                            .font(.system(size: 12))
                            .foregroundStyle(theme.foregroundSecondary)
                    }

                    if bluetoothManager.connectionState.isBluetoothUnavailable {
                        Button {
                            openBluetoothSettings()
                        } label: {
                            Text("Allow Bluetooth")
                                .font(.system(size: 11, weight: .medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(theme.accent)
                                .foregroundStyle(theme.background)
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 12)
            }

            Rectangle()
                .fill(theme.divider)
                .frame(height: 1)

            // Minimal actions
            MinimalActionsRow(bluetoothManager: bluetoothManager)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(width: 180)
        .background(theme.background)
    }
}

struct MinimalBattery: View {
    let label: String
    let percentage: Int?
    @Environment(\.colorTheme) var theme

    private var color: Color {
        guard let pct = percentage else { return theme.foregroundTertiary }
        return theme.batteryColor(for: pct)
    }

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(theme.foregroundTertiary)
            Text(percentage.map { "\($0)%" } ?? "--")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(color)
        }
    }
}

struct MinimalActionsRow: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        HStack(spacing: 12) {
            if bluetoothManager.connectionState.isConnected {
                MinimalIconButton(icon: "arrow.clockwise", help: "Refresh") {
                    bluetoothManager.refreshBatteryLevels()
                }
            } else {
                MinimalIconButton(icon: "antenna.radiowaves.left.and.right", help: "Scan") {
                    bluetoothManager.startScanning()
                }
            }

            Spacer()

            MinimalIconButton(icon: "gear", help: "Settings") {
                openSettings()
                NSApp.activate(ignoringOtherApps: true)
            }

            MinimalIconButton(icon: "power", help: "Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(.vertical, 10)
    }
}

struct MinimalIconButton: View {
    let icon: String
    let help: String
    let action: () -> Void
    @State private var isHovered = false
    @Environment(\.colorTheme) var theme

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(isHovered ? theme.foreground : theme.foregroundSecondary)
                .padding(6)
                .background(isHovered ? theme.foreground.opacity(0.1) : Color.clear)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help(help)
    }
}

// MARK: - =====================================================
// MARK: - TUI STYLE (Terminal UI - supports all themes)
// MARK: - =====================================================

struct TUIMenuBarView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @Environment(\.colorTheme) var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            Text("bat-mon")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(theme.accent)

            if let keyboard = bluetoothManager.selectedKeyboard,
               bluetoothManager.connectionState.isConnected {
                // Device with status
                HStack {
                    Text(keyboard.effectiveName)
                        .foregroundStyle(theme.foreground)
                    Spacer()
                    Text("●")
                        .foregroundStyle(theme.success)
                }

                TUIDivider()

                // Battery displays
                TUIBatteryBar(label: "LEFT ", percentage: keyboard.leftBattery?.percentage)
                TUIBatteryBar(label: "RIGHT", percentage: keyboard.rightBattery?.percentage)

                // Timestamp
                if let time = keyboard.leftBattery?.timestamp ?? keyboard.rightBattery?.timestamp {
                    Text(time.timeAgoDisplay())
                        .foregroundStyle(theme.foregroundTertiary)
                        .font(.system(size: 10, design: .monospaced))
                }
            } else {
                // Disconnected
                HStack {
                    Text(bluetoothManager.connectionState.displayText)
                        .foregroundStyle(theme.foreground)
                    Spacer()
                    Text(bluetoothManager.connectionState.isActive ? "◐" : "○")
                        .foregroundStyle(bluetoothManager.connectionState.isActive ? theme.warning : theme.error)
                }

                if bluetoothManager.connectionState.isBluetoothUnavailable {
                    Button {
                        openBluetoothSettings()
                    } label: {
                        Text("~ allow-bluetooth")
                            .foregroundStyle(theme.accent)
                    }
                    .buttonStyle(.plain)
                }
            }

            TUIDivider()

            // Actions
            TUIActionsSection(bluetoothManager: bluetoothManager)
        }
        .font(.system(size: 11, design: .monospaced))
        .padding(12)
        .frame(width: 220)
        .background(theme.background)
    }
}

struct TUIBatteryBar: View {
    let label: String
    let percentage: Int?
    @Environment(\.colorTheme) var theme

    private var barColor: Color {
        guard let pct = percentage else { return theme.foregroundTertiary }
        return theme.batteryColor(for: pct)
    }

    private func renderBar(_ pct: Int) -> String {
        let total = 10
        let filled = Int(Double(pct) / 100.0 * Double(total))
        let empty = total - filled
        return String(repeating: "━", count: filled) + String(repeating: "─", count: empty)
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .foregroundStyle(theme.foregroundSecondary)
            if let pct = percentage {
                Text(renderBar(pct))
                    .foregroundStyle(barColor)
                Text("\(String(format: "%3d", pct))%")
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

struct TUIDivider: View {
    @Environment(\.colorTheme) var theme

    var body: some View {
        Rectangle()
            .fill(theme.divider)
            .frame(height: 1)
            .padding(.vertical, 4)
    }
}

struct TUIActionsSection: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @Environment(\.openSettings) private var openSettings
    @Environment(\.colorTheme) var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if bluetoothManager.connectionState.isConnected {
                TUIMenuItem(label: "refresh", color: theme.accent) {
                    bluetoothManager.refreshBatteryLevels()
                }
                TUIMenuItem(label: "disconnect", color: theme.warning) {
                    bluetoothManager.disconnect()
                }
            } else {
                TUIMenuItem(label: "scan", color: theme.accent) {
                    bluetoothManager.startScanning()
                }
            }
            TUIMenuItem(label: "settings", color: theme.foregroundSecondary) {
                openSettings()
                NSApp.activate(ignoringOtherApps: true)
            }
            TUIMenuItem(label: "quit", color: theme.error) {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

struct TUIMenuItem: View {
    let label: String
    let color: Color
    let action: () -> Void
    @State private var isHovered = false
    @Environment(\.colorTheme) var theme

    var body: some View {
        Button(action: action) {
            HStack {
                Text("~")
                    .foregroundStyle(theme.accent)
                Text(label)
                    .foregroundStyle(isHovered ? theme.foreground : color)
                Spacer()
            }
            .font(.system(size: 11, design: .monospaced))
            .padding(.vertical, 2)
            .padding(.horizontal, 4)
            .background(isHovered ? theme.backgroundSecondary : Color.clear)
            .cornerRadius(4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
