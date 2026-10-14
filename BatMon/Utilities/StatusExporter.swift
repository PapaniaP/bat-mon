import Foundation
import os.log

struct StatusSnapshot: Encodable {
    var connectionState: String
    let keyboardName: String?
    let leftPercent: Int?
    let rightPercent: Int?
    let leftBatteryReadAt: Date?
    let rightBatteryReadAt: Date?
    var exportedAt: Date
    let pollingIntervalSeconds: TimeInterval
    let lowBatteryThreshold: Int
    let criticalBatteryThreshold: Int

    init(keyboard: ZMKKeyboard?, connectionState: ConnectionState,
         pollingIntervalSeconds: TimeInterval, lowBatteryThreshold: Int,
         criticalBatteryThreshold: Int, exportedAt: Date = Date()) {
        switch connectionState {
        case .disconnected: self.connectionState = "disconnected"
        case .idle: self.connectionState = "idle"
        case .searching: self.connectionState = "searching"
        case .connecting: self.connectionState = "connecting"
        case .connected: self.connectionState = "connected"
        case .reconnecting: self.connectionState = "reconnecting"
        case .failed: self.connectionState = "failed"
        }
        keyboardName = keyboard?.effectiveName
        leftPercent = keyboard?.leftBattery?.percentage
        rightPercent = keyboard?.rightBattery?.percentage
        leftBatteryReadAt = keyboard?.leftBattery?.timestamp
        rightBatteryReadAt = keyboard?.rightBattery?.timestamp
        self.exportedAt = exportedAt
        self.pollingIntervalSeconds = pollingIntervalSeconds
        self.lowBatteryThreshold = lowBatteryThreshold
        self.criticalBatteryThreshold = criticalBatteryThreshold
    }

    private enum CodingKeys: String, CodingKey {
        case version, connectionState, keyboardName, leftPercent, rightPercent
        case leftBatteryReadAt, rightBatteryReadAt, exportedAt
        case pollingIntervalSeconds, lowBatteryThreshold, criticalBatteryThreshold
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(1, forKey: .version)
        try container.encode(connectionState, forKey: .connectionState)
        // Optional values must remain explicit nulls in the consumer contract.
        try container.encode(keyboardName, forKey: .keyboardName)
        try container.encode(leftPercent, forKey: .leftPercent)
        try container.encode(rightPercent, forKey: .rightPercent)
        try container.encode(leftBatteryReadAt, forKey: .leftBatteryReadAt)
        try container.encode(rightBatteryReadAt, forKey: .rightBatteryReadAt)
        try container.encode(exportedAt, forKey: .exportedAt)
        try container.encode(pollingIntervalSeconds, forKey: .pollingIntervalSeconds)
        try container.encode(lowBatteryThreshold, forKey: .lowBatteryThreshold)
        try container.encode(criticalBatteryThreshold, forKey: .criticalBatteryThreshold)
    }
}

final class StatusExporter {
    static var defaultFileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")
        return appSupport.appendingPathComponent("BatMon/status.json")
    }

    private let fileURL: URL
    private let write: (Data, URL) throws -> Void
    private let queue = DispatchQueue(label: "com.paolo.bat-mon.status-export", qos: .utility)
    private let logger = Logger(subsystem: AppInfo.bundleIdentifier, category: "StatusExport")
    private let shutdownGroup = DispatchGroup()
    private var acceptingSnapshots = true
    private var lastSnapshot: StatusSnapshot?
    private var finalWriteSucceeded = true

    init(fileURL: URL = StatusExporter.defaultFileURL,
         write: @escaping (Data, URL) throws -> Void = StatusExporter.writeAtomically) {
        self.fileURL = fileURL
        self.write = write
    }

    func submit(_ snapshot: StatusSnapshot) {
        precondition(Thread.isMainThread)
        guard acceptingSnapshots else { return }
        lastSnapshot = snapshot
        queue.async { self.writeSnapshot(snapshot) }
    }

    @discardableResult
    func shutdown(timeout: TimeInterval = 1) -> Bool {
        precondition(Thread.isMainThread)
        if acceptingSnapshots {
            acceptingSnapshots = false
            if var snapshot = lastSnapshot {
                snapshot.connectionState = "disconnected"
                snapshot.exportedAt = Date()
                let finalSnapshot = snapshot
                // Termination waits for this work, so prioritize the final flush.
                queue.async(group: shutdownGroup, qos: .userInteractive) {
                    self.finalWriteSucceeded = self.writeSnapshot(finalSnapshot)
                }
            }
        }
        guard shutdownGroup.wait(timeout: .now() + timeout) == .success else {
            logger.error("Status export shutdown flush timed out")
            return false
        }
        return finalWriteSucceeded
    }

    @discardableResult
    private func writeSnapshot(_ snapshot: StatusSnapshot) -> Bool {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            try write(encoder.encode(snapshot), fileURL)
            return true
        } catch {
            logger.error("Status export failed: \(error.localizedDescription)")
            return false
        }
    }

    static func writeAtomically(_ data: Data, _ url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }
}
