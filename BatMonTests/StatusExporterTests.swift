import Foundation
import XCTest

final class StatusExporterTests: XCTestCase {
    private let epoch = Date(timeIntervalSince1970: 0)

    func testUnknownValuesAreExplicitNulls() throws {
        let json = try encode(snapshot())
        XCTAssertEqual(Set(json.keys), Set([
            "version", "connectionState", "keyboardName", "leftPercent", "rightPercent",
            "leftBatteryReadAt", "rightBatteryReadAt", "exportedAt", "pollingIntervalSeconds",
            "lowBatteryThreshold", "criticalBatteryThreshold"
        ]))
        for key in ["keyboardName", "leftPercent", "rightPercent", "leftBatteryReadAt", "rightBatteryReadAt"] {
            XCTAssertTrue(json[key] is NSNull, key)
        }
        XCTAssertEqual(json["version"] as? Int, 1)
        XCTAssertEqual(json["exportedAt"] as? String, "1970-01-01T00:00:00Z")
    }

    func testZeroAndIndependentReadTimestampsSurviveEncoding() throws {
        var keyboard = keyboard()
        keyboard.displayName = "Desk \"keyboard\" 🦇"
        keyboard.leftBattery = BatteryLevel(percentage: 0, timestamp: epoch)
        keyboard.rightBattery = BatteryLevel(percentage: 90, timestamp: epoch.addingTimeInterval(60))
        let captured = snapshot(keyboard: keyboard, state: .connected)
        keyboard.leftBattery = BatteryLevel(percentage: 99, timestamp: Date())
        let json = try encode(captured)
        XCTAssertEqual(json["keyboardName"] as? String, "Desk \"keyboard\" 🦇")
        XCTAssertEqual(json["leftPercent"] as? Int, 0)
        XCTAssertEqual(json["rightPercent"] as? Int, 90)
        XCTAssertEqual(json["leftBatteryReadAt"] as? String, "1970-01-01T00:00:00Z")
        XCTAssertEqual(json["rightBatteryReadAt"] as? String, "1970-01-01T00:01:00Z")
        XCTAssertEqual(json["pollingIntervalSeconds"] as? Double, 30)
        XCTAssertEqual(json["lowBatteryThreshold"] as? Int, 25)
        XCTAssertEqual(json["criticalBatteryThreshold"] as? Int, 5)
        XCTAssertFalse(String(decoding: try data(captured), as: UTF8.self).contains(keyboard.peripheralIdentifier.uuidString))
    }

    func testOneMissingHalfDoesNotBecomeZero() throws {
        var keyboard = keyboard()
        keyboard.leftBattery = BatteryLevel(percentage: 85, timestamp: epoch)
        let json = try encode(snapshot(keyboard: keyboard, state: .connected))
        XCTAssertEqual(json["leftPercent"] as? Int, 85)
        XCTAssertTrue(json["rightPercent"] is NSNull)
        XCTAssertTrue(json["rightBatteryReadAt"] is NSNull)
    }

    func testConnectionStateStringsDoNotExposeFailureDetails() throws {
        let cases: [(ConnectionState, String)] = [
            (.disconnected, "disconnected"), (.idle, "idle"), (.searching, "searching"),
            (.connecting, "connecting"), (.connected, "connected"),
            (.reconnecting(attempt: 2, maxAttempts: 10), "reconnecting"),
            (.failed("private failure detail"), "failed")
        ]
        for (state, expected) in cases {
            XCTAssertEqual(try encode(snapshot(state: state))["connectionState"] as? String, expected)
        }
    }

    func testWritesRemainOrderedAndUnchangedPercentagesGetFreshTimestamps() {
        onMain {
            var documents: [[String: Any]] = []
            let exporter = StatusExporter(fileURL: temporaryURL()) { data, _ in
                documents.append(try self.decode(data))
            }
            var keyboard = keyboard()
            keyboard.leftBattery = BatteryLevel(percentage: 85, timestamp: epoch)
            exporter.submit(snapshot(keyboard: keyboard, state: .connected))
            keyboard.leftBattery = BatteryLevel(percentage: 85, timestamp: epoch.addingTimeInterval(60))
            exporter.submit(snapshot(keyboard: keyboard, state: .connected))
            exporter.submit(snapshot(state: .disconnected))
            XCTAssertTrue(exporter.shutdown())
            XCTAssertEqual(documents.count, 4)
            XCTAssertEqual(documents[0]["leftBatteryReadAt"] as? String, "1970-01-01T00:00:00Z")
            XCTAssertEqual(documents[1]["leftBatteryReadAt"] as? String, "1970-01-01T00:01:00Z")
            XCTAssertEqual(documents[1]["leftPercent"] as? Int, 85)
            XCTAssertTrue(documents[2]["keyboardName"] is NSNull)
            XCTAssertTrue(documents[2]["leftPercent"] is NSNull)
            XCTAssertEqual(documents[3]["connectionState"] as? String, "disconnected")
        }
    }

    func testAtomicFileReplacementAndShutdownFlush() throws {
        try onMain {
            let url = temporaryURL()
            defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
            let exporter = StatusExporter(fileURL: url)
            var keyboard = keyboard()
            keyboard.leftBattery = BatteryLevel(percentage: 85, timestamp: epoch)
            exporter.submit(snapshot(keyboard: keyboard, state: .connected))
            exporter.submit(snapshot(keyboard: keyboard, state: .connected))
            XCTAssertTrue(exporter.shutdown())
            let bytes = try Data(contentsOf: url)
            let json = try decode(bytes)
            XCTAssertEqual(json["connectionState"] as? String, "disconnected")
            XCTAssertEqual(json["leftPercent"] as? Int, 85)
            XCTAssertEqual(json["leftBatteryReadAt"] as? String, "1970-01-01T00:00:00Z")
            XCTAssertNotEqual(json["exportedAt"] as? String, "1970-01-01T00:00:00Z")
            exporter.submit(snapshot(state: .connected))
            XCTAssertTrue(exporter.shutdown())
            XCTAssertEqual(try Data(contentsOf: url), bytes)
        }
    }

    func testWriteFailureDoesNotStopFutureSnapshots() throws {
        try onMain {
            let url = temporaryURL()
            defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
            var attempts = 0
            let exporter = StatusExporter(fileURL: url) { data, destination in
                attempts += 1
                if attempts == 1 { throw CocoaError(.fileWriteNoPermission) }
                try StatusExporter.writeAtomically(data, destination)
            }
            exporter.submit(snapshot(state: .connected))
            exporter.submit(snapshot(state: .idle))
            XCTAssertTrue(exporter.shutdown())
            XCTAssertEqual(attempts, 3)
            XCTAssertEqual(try decode(Data(contentsOf: url))["connectionState"] as? String, "disconnected")
        }
    }

    func testFailedReplacementPreservesPreviousDocument() throws {
        let url = temporaryURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let original = try data(snapshot())
        try StatusExporter.writeAtomically(original, url)
        // Using the existing file as a parent fails before touching its contents.
        XCTAssertThrowsError(try StatusExporter.writeAtomically(Data("new".utf8), url.appendingPathComponent("status.json")))
        XCTAssertEqual(try Data(contentsOf: url), original)
    }

    func testFailedFinalWriteReportsFailure() throws {
        onMain {
            let exporter = StatusExporter(fileURL: temporaryURL()) { _, _ in
                throw CocoaError(.fileWriteNoPermission)
            }
            exporter.submit(snapshot())
            XCTAssertFalse(exporter.shutdown())
            XCTAssertFalse(exporter.shutdown())
        }
    }

    func testSlowWriterDoesNotBlockSubmitOrExceedShutdownDeadline() throws {
        onMain {
            let gate = DispatchSemaphore(value: 0)
            var writes = 0
            let exporter = StatusExporter(fileURL: temporaryURL()) { _, _ in
                writes += 1
                if writes == 1 { gate.wait() }
            }
            let start = Date()
            exporter.submit(snapshot(state: .connected))
            exporter.submit(snapshot(state: .idle))
            XCTAssertLessThan(Date().timeIntervalSince(start), 0.5)
            XCTAssertFalse(exporter.shutdown(timeout: 0.02))
            XCTAssertFalse(exporter.shutdown(timeout: 0.02))
            XCTAssertLessThan(Date().timeIntervalSince(start), 0.5)
            exporter.submit(snapshot(state: .connected))
            gate.signal()
            XCTAssertTrue(exporter.shutdown())
            XCTAssertEqual(writes, 3)
            XCTAssertTrue(exporter.shutdown())
            XCTAssertEqual(writes, 3)
        }
    }

    private func snapshot(keyboard: ZMKKeyboard? = nil, state: ConnectionState = .disconnected) -> StatusSnapshot {
        StatusSnapshot(keyboard: keyboard, connectionState: state, pollingIntervalSeconds: 30,
                       lowBatteryThreshold: 25, criticalBatteryThreshold: 5, exportedAt: epoch)
    }

    private func keyboard() -> ZMKKeyboard {
        ZMKKeyboard(name: "My keyboard", peripheralIdentifier: UUID())
    }

    private func temporaryURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("status.json")
    }

    private func data(_ snapshot: StatusSnapshot) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(snapshot)
    }

    private func encode(_ snapshot: StatusSnapshot) throws -> [String: Any] {
        try decode(data(snapshot))
    }

    private func decode(_ data: Data) throws -> [String: Any] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func onMain(_ body: () throws -> Void) rethrows {
        if Thread.isMainThread { try body() }
        else { try DispatchQueue.main.sync(execute: body) }
    }
}
