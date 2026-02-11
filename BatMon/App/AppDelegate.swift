import AppKit
import UserNotifications
import os.log

class AppDelegate: NSObject, NSApplicationDelegate {
    private let logger = Logger(subsystem: AppInfo.bundleIdentifier, category: "AppDelegate")

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request notification permissions
        requestNotificationPermissions()

        // Subscribe to system wake notifications for reconnection
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    @objc private func systemDidWake(_ notification: Notification) {
        // Post notification for BluetoothManager to handle reconnection
        NotificationCenter.default.post(name: .systemDidWake, object: nil)
    }

    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { [weak self] granted, error in
            if let error = error {
                self?.logger.error("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
}

extension Notification.Name {
    static let systemDidWake = Notification.Name("systemDidWake")
}
