import Foundation
import ServiceManagement
import os.log

enum LaunchAtLogin {
    private static let logger = Logger(subsystem: AppInfo.bundleIdentifier, category: "LaunchAtLogin")

    static var isEnabled: Bool {
        get {
            SMAppService.mainApp.status == .enabled
        }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                logger.error("Failed to \(newValue ? "enable" : "disable") launch at login: \(error.localizedDescription)")
            }
        }
    }
}
