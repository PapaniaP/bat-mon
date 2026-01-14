import AppKit
import UserNotifications
import os.log

class AppDelegate: NSObject, NSApplicationDelegate {
    private let logger = Logger(subsystem: AppInfo.bundleIdentifier, category: "AppDelegate")

    /// Performs startup tasks after the application finishes launching.
    /// 
    /// Requests user notification permissions and subscribes to system wake notifications to handle reconnection when the system wakes.
    /// - Parameter notification: The launch notification delivered by the application.
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

    /// Handles system wake events by posting an internal `.systemDidWake` notification.
    /// - Parameter notification: The wake `Notification` delivered by `NSWorkspace` when the system wakes.
    @objc private func systemDidWake(_ notification: Notification) {
        // Post notification for BluetoothManager to handle reconnection
        NotificationCenter.default.post(name: .systemDidWake, object: nil)
    }

    /// Requests user authorization for local notifications with alert and sound options.
    /// Logs any authorization error to the delegate's logger.
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