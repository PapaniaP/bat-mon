import SwiftUI

@main
struct BatMonApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var bluetoothManager = BluetoothManager()
    @StateObject private var preferencesManager = PreferencesManager.shared

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(bluetoothManager)
                .environmentObject(preferencesManager)
        } label: {
            MenuBarLabel(bluetoothManager: bluetoothManager, settings: preferencesManager.settings)
        }

        Settings {
            SettingsView()
                .environmentObject(bluetoothManager)
                .environmentObject(preferencesManager)
        }
    }
}

struct MenuBarLabel: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    let settings: AppSettings

    var body: some View {
        HStack(spacing: 4) {
            if settings.menuBarIcon != .none {
                Image(systemName: settings.menuBarIcon.sfSymbolName)
            }

            if let keyboard = bluetoothManager.selectedKeyboard,
               bluetoothManager.connectionState.isConnected {
                Text(formatBatteryDisplay(keyboard: keyboard))
                    .monospacedDigit()
            } else {
                Text("--")
                    .foregroundColor(.secondary)
            }
        }
    }

    private func formatBatteryDisplay(keyboard: ZMKKeyboard) -> String {
        let left = keyboard.leftBattery?.percentage
        let right = keyboard.rightBattery?.percentage

        switch settings.displayFormat {
        case .percentageWithIcon:
            let leftStr = left.map { "\($0)%" } ?? "--"
            let rightStr = right.map { "\($0)%" } ?? "--"
            return "\(leftStr)\(settings.separator)\(rightStr)"

        case .percentageOnly:
            let leftStr = left.map { "\($0)" } ?? "--"
            let rightStr = right.map { "\($0)" } ?? "--"
            return "\(leftStr) \(rightStr)"

        case .visualBars:
            let leftBar = left.map { BatteryLevel(percentage: $0, timestamp: Date()).visualBar } ?? "-----"
            let rightBar = right.map { BatteryLevel(percentage: $0, timestamp: Date()).visualBar } ?? "-----"
            return "\(leftBar) \(rightBar)"
        }
    }
}
