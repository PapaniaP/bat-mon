import Foundation
import Combine
import os.log
import WidgetKit

class PreferencesManager: ObservableObject {
    static let shared = PreferencesManager()

    @Published var settings: AppSettings {
        didSet {
            saveSettings()
        }
    }

    @Published var hasCompletedSetup: Bool

    private let defaults = UserDefaults(suiteName: AppInfo.appGroupIdentifier) ?? .standard
    private let logger = Logger(subsystem: AppInfo.bundleIdentifier, category: "Preferences")

    private init() {
        // Load settings or use defaults
        if let data = defaults.data(forKey: UserDefaultsKeys.appSettings),
           var loaded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            // Migrate from old MenuStyle to new Layout + Theme system
            loaded.migrateFromMenuStyleIfNeeded()
            self.settings = loaded
        } else {
            self.settings = AppSettings()
        }

        self.hasCompletedSetup = defaults.bool(forKey: UserDefaultsKeys.hasCompletedSetup)

        // Save settings after migration (if any occurred)
        saveSettings()
    }

    // MARK: - Settings

    func saveSettings() {
        do {
            let data = try JSONEncoder().encode(settings)
            defaults.set(data, forKey: UserDefaultsKeys.appSettings)

            // Sync theme to widget
            defaults.set(settings.colorThemeId, forKey: UserDefaultsKeys.widgetThemeId)
            defaults.set(settings.menuLayout.rawValue, forKey: UserDefaultsKeys.widgetMenuLayout)
            WidgetCenter.shared.reloadAllTimelines()

            logger.info("Settings saved")
        } catch {
            logger.error("Failed to save settings: \(error.localizedDescription)")
        }
    }

    func resetToDefaults() {
        settings = AppSettings()
        logger.info("Settings reset to defaults")
    }

    // MARK: - Keyboard Persistence

    func saveKeyboard(_ keyboard: ZMKKeyboard) {
        do {
            let data = try JSONEncoder().encode(keyboard)
            defaults.set(data, forKey: UserDefaultsKeys.selectedKeyboardData)
            logger.info("Saved keyboard: \(keyboard.name)")
        } catch {
            logger.error("Failed to save keyboard: \(error.localizedDescription)")
        }
    }

    func loadLastSelectedKeyboard() -> ZMKKeyboard? {
        guard let data = defaults.data(forKey: UserDefaultsKeys.selectedKeyboardData) else {
            return nil
        }

        do {
            let keyboard = try JSONDecoder().decode(ZMKKeyboard.self, from: data)
            logger.info("Loaded keyboard: \(keyboard.name)")
            return keyboard
        } catch {
            logger.error("Failed to load keyboard: \(error.localizedDescription)")
            return nil
        }
    }

    func clearSelectedKeyboard() {
        defaults.removeObject(forKey: UserDefaultsKeys.selectedKeyboardData)
        logger.info("Cleared selected keyboard")
    }

    // MARK: - Multiple Keyboards

    func saveKeyboards(_ keyboards: [ZMKKeyboard]) {
        do {
            let data = try JSONEncoder().encode(keyboards)
            defaults.set(data, forKey: UserDefaultsKeys.savedKeyboards)
            logger.info("Saved \(keyboards.count) keyboards")
        } catch {
            logger.error("Failed to save keyboards: \(error.localizedDescription)")
        }
    }

    func loadSavedKeyboards() -> [ZMKKeyboard] {
        guard let data = defaults.data(forKey: UserDefaultsKeys.savedKeyboards) else {
            return []
        }

        do {
            let keyboards = try JSONDecoder().decode([ZMKKeyboard].self, from: data)
            logger.info("Loaded \(keyboards.count) saved keyboards")
            return keyboards
        } catch {
            logger.error("Failed to load keyboards: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Setup State

    func markSetupComplete() {
        hasCompletedSetup = true
        defaults.set(true, forKey: UserDefaultsKeys.hasCompletedSetup)
        logger.info("Setup marked as complete")
    }

    func resetSetup() {
        hasCompletedSetup = false
        defaults.set(false, forKey: UserDefaultsKeys.hasCompletedSetup)
        logger.info("Setup state reset")
    }
}
