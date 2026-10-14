import Foundation
import CoreBluetooth

enum BLEConstants {
    /// Standard Bluetooth Battery Service UUID
    static let batteryServiceUUID = CBUUID(string: "180F")
    /// Standard Bluetooth Battery Level Characteristic UUID (percentage 0-100)
    static let batteryLevelCharacteristicUUID = CBUUID(string: "2A19")

    static let scanTimeout: TimeInterval = 10.0
    static let connectTimeout: TimeInterval = 10.0
}

enum AppConstants {
    // Polling
    static let defaultPollingInterval: TimeInterval = 60.0
    static let minPollingInterval: TimeInterval = 10.0
    static let maxPollingInterval: TimeInterval = 300.0

    // Battery thresholds
    static let defaultLowBatteryThreshold = 20
    static let defaultCriticalBatteryThreshold = 10
    static let minBatteryThreshold = 5
    static let maxBatteryThreshold = 50

    // Reconnection
    static let reconnectBaseDelay: TimeInterval = 1.0
    static let reconnectMaxDelay: TimeInterval = 30.0
    static let defaultMaxReconnectAttempts = 10

    // UI
    static let menuBarUpdateThrottle: TimeInterval = 1.0
    static let notificationCooldown: TimeInterval = 3600.0
}

enum ReconnectPolicy {
    static func shouldStart(
        hasSavedKeyboard: Bool,
        bluetoothIsPoweredOn: Bool,
        isEnabled: Bool
    ) -> Bool {
        hasSavedKeyboard && bluetoothIsPoweredOn && isEnabled
    }
}

enum UserDefaultsKeys {
    static let appSettings = "appSettings"
    static let selectedKeyboardData = "selectedKeyboardData"
    static let savedKeyboards = "savedKeyboards"
    static let hasCompletedSetup = "hasCompletedSetup"
}

enum PreferencesMigration {
    static func migrate(from legacy: UserDefaults, to defaults: UserDefaults) {
        let marker = "didMigrateLegacyAppGroupDefaults"
        guard !defaults.bool(forKey: marker) else { return }
        let keys = [UserDefaultsKeys.appSettings, UserDefaultsKeys.selectedKeyboardData,
                    UserDefaultsKeys.savedKeyboards, UserDefaultsKeys.hasCompletedSetup]
        // An established domain may intentionally have forgotten its old keyboard.
        if keys.allSatisfy({ defaults.object(forKey: $0) == nil }) {
            for key in keys {
                if let value = legacy.object(forKey: key) { defaults.set(value, forKey: key) }
            }
        }
        defaults.set(true, forKey: marker)
    }
}

enum AppInfo {
    static let appName = "BatMon"
    static let bundleIdentifier = "com.paolo.bat-mon"
    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }
    static var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    static func displayVersion(version: String = version, build: String = buildNumber, isLocalTest: Bool = isLocalTest) -> String {
        let label = "Version \(version) (\(build))"
        return isLocalTest ? "\(label) • Local Test" : label
    }

    private static var isLocalTest: Bool {
#if DEBUG
        true
#else
        false
#endif
    }

    static let githubURL = "https://github.com/PapaniaP/bat-mon"
}
