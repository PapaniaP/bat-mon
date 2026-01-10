import Foundation
import UserNotifications
import os.log

class NotificationManager {
    static let shared = NotificationManager()

    private let notificationCenter = UNUserNotificationCenter.current()
    private var sentNotifications: Set<String> = []
    private let logger = Logger(subsystem: AppInfo.bundleIdentifier, category: "Notifications")

    private init() {}

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound])
            logger.info("Notification permission: \(granted ? "granted" : "denied")")
            return granted
        } catch {
            logger.error("Notification permission error: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Battery Alerts

    func sendLowBatteryAlert(keyboard: ZMKKeyboard, half: KeyboardHalf, percentage: Int) {
        let identifier = "low-battery-\(keyboard.id)-\(half.rawValue)"

        guard shouldSendNotification(identifier: identifier) else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Low Battery Warning"
        content.body = "\(keyboard.effectiveName) - \(half.rawValue) half is at \(percentage)%"
        content.sound = .default
        content.categoryIdentifier = "BATTERY_ALERT"

        sendNotification(identifier: identifier, content: content)
    }

    func sendCriticalBatteryAlert(keyboard: ZMKKeyboard, half: KeyboardHalf, percentage: Int) {
        let identifier = "critical-battery-\(keyboard.id)-\(half.rawValue)"

        guard shouldSendNotification(identifier: identifier) else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Critical Battery!"
        content.body = "\(keyboard.effectiveName) - \(half.rawValue) half is at \(percentage)%. Charge soon!"
        content.sound = .defaultCritical
        content.categoryIdentifier = "BATTERY_CRITICAL"

        sendNotification(identifier: identifier, content: content)
    }

    func sendDisconnectAlert(keyboard: ZMKKeyboard) {
        let identifier = "disconnect-\(keyboard.id)"

        guard shouldSendNotification(identifier: identifier) else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Keyboard Disconnected"
        content.body = "\(keyboard.effectiveName) has disconnected"
        content.sound = .default
        content.categoryIdentifier = "CONNECTION"

        sendNotification(identifier: identifier, content: content)
    }

    func sendReconnectAlert(keyboard: ZMKKeyboard) {
        let identifier = "reconnect-\(keyboard.id)"

        // Clear disconnect notification
        notificationCenter.removeDeliveredNotifications(withIdentifiers: ["disconnect-\(keyboard.id)"])

        guard shouldSendNotification(identifier: identifier) else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Keyboard Connected"
        content.body = "\(keyboard.effectiveName) has reconnected"
        content.sound = .default
        content.categoryIdentifier = "CONNECTION"

        sendNotification(identifier: identifier, content: content)
    }

    // MARK: - Helpers

    private func sendNotification(identifier: String, content: UNMutableNotificationContent) {
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )

        notificationCenter.add(request) { [weak self] error in
            if let error = error {
                self?.logger.error("Failed to send notification: \(error.localizedDescription)")
            } else {
                self?.markNotificationSent(identifier: identifier)
                self?.logger.info("Sent notification: \(identifier)")
            }
        }
    }

    private func shouldSendNotification(identifier: String) -> Bool {
        guard PreferencesManager.shared.settings.enableNotifications else {
            return false
        }

        if sentNotifications.contains(identifier) {
            logger.debug("Notification \(identifier) already sent recently")
            return false
        }

        return true
    }

    private func markNotificationSent(identifier: String) {
        sentNotifications.insert(identifier)

        // Clear after cooldown period
        DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.notificationCooldown) { [weak self] in
            self?.sentNotifications.remove(identifier)
        }
    }

    // MARK: - Test

    func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "BatMon Test"
        content.body = "Notifications are working!"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "test-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        notificationCenter.add(request) { [weak self] error in
            if let error = error {
                self?.logger.error("Test notification failed: \(error.localizedDescription)")
            } else {
                self?.logger.info("Test notification sent")
            }
        }
    }
}
