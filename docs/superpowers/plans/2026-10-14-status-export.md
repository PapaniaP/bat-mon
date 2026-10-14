# BatMon Status Export Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans for native execution or superpowers:subagent-driven-development if the user selects delegation. Steps use checkbox syntax for tracking.

**Goal:** Produce the approved version-one local status file for a separate SketchyBar consumer.

**Architecture:** BluetoothManager captures complete value snapshots from Combine publications on the main thread. A retained exporter writes them atomically on one background queue. AppDelegate synchronously signals shutdown; the exporter rejects new work and waits at most one second for its final disconnected write.

**Tech Stack:** Swift, Foundation, Combine, os.Logger, XCTest; existing Xcode project.

**Spec:** [Approved design](../specs/2026-10-14-status-export-design.md)

## Global Constraints

- No SketchyBar configuration, external executable invocation, new dependency, or sandbox change.
- All JSON keys are present; optional values are explicit nulls and dates are UTC ISO 8601.
- Preserve existing uncommitted changes. Do not install or replace the running app as part of building.
- Main-thread snapshot capture; serial background file writes; one-second maximum shutdown wait.
- No Bluetooth identifiers, error messages, or unrelated preferences in the export.

## Review Focus

- A display name containing quotes or Unicode must round-trip through JSON.
- A failed filesystem write must leave the previous valid snapshot and allow a later successful write.
- A slow writer must not block Bluetooth callbacks or hang termination beyond the deadline.
- An unchanged percentage with a newer timestamp must cause a new export.
- A forget/disconnect transition must not leave the consumer displaying connected numbers after the final event.

## Task 1: Status snapshot and ordered writer

**Files:** Create `BatMon/Utilities/StatusExporter.swift`, `BatMonTests/StatusExporterTests.swift`; modify `BatMon.xcodeproj/project.pbxproj`.

**Interfaces:**

```swift
struct StatusSnapshot: Encodable {
    init(keyboard: ZMKKeyboard?, connectionState: ConnectionState,
         pollingIntervalSeconds: TimeInterval, lowBatteryThreshold: Int,
         criticalBatteryThreshold: Int, exportedAt: Date = Date())
}

final class StatusExporter {
    init(fileURL: URL = StatusExporter.defaultFileURL,
         write: @escaping (Data, URL) throws -> Void = StatusExporter.writeAtomically)
    func submit(_ snapshot: StatusSnapshot)
    @discardableResult func shutdown(timeout: TimeInterval = 1) -> Bool
}
```

`submit` and `shutdown` run on the main thread. The injected write closure is the
filesystem seam used to verify errors and stalled writes without real hardware.
The exporter retains the last accepted value snapshot to construct shutdown state.
No Bluetooth or preference objects cross into the background closure.

- [x] Add the exporter/test file references and source membership. The test target currently compiles selected app sources directly: add the exporter plus `ZMKKeyboard.swift`, `BatteryLevel.swift`, and `ConnectionState.swift` to its Sources phase. Retain its existing theme, Constants, and XCTest sources.
- [x] Write failing contract tests using JSONSerialization to inspect the encoded object:

```swift
let snapshot = StatusSnapshot(keyboard: nil, connectionState: .disconnected,
    pollingIntervalSeconds: 60, lowBatteryThreshold: 20,
    criticalBatteryThreshold: 10, exportedAt: Date(timeIntervalSince1970: 0))
let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .iso8601
let json = try XCTUnwrap(JSONSerialization.jsonObject(
    with: encoder.encode(snapshot)) as? [String: Any])
XCTAssertEqual(json["version"] as? Int, 1)
XCTAssertTrue(json["leftPercent"] is NSNull)
XCTAssertTrue(json["keyboardName"] is NSNull)
XCTAssertEqual(json["exportedAt"] as? String, "1970-01-01T00:00:00Z")
XCTAssertEqual(json.count, 11)
```

  Add fixtures for valid zero, one missing half, independent half timestamps,
  escaped/Unicode effectiveName, every ConnectionState case, and thresholds.
  Ensure no identifier or associated failure message appears in JSON.
- [x] Run the test command below and confirm failures are caused by missing exporter implementation.
- [x] Implement StatusSnapshot as a value type with explicit keyed encoding. Use `encode(optional, forKey:)` rather than `encodeIfPresent` to preserve nulls. Map the seven ConnectionState cases to the exact strings in the spec. Read effectiveName and each battery's percentage/timestamp from the supplied keyboard, with no new date substituted for battery timestamps.
- [x] Implement the default URL using Foundation's user Application Support directory plus `BatMon/status.json`, following CustomThemeLoader's fallback convention. Implement the writer with:

```swift
static func writeAtomically(_ data: Data, _ url: URL) throws {
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
        withIntermediateDirectories: true)
    try data.write(to: url, options: .atomic)
}
```

- [x] Implement submit: guard acceptance, retain the value snapshot, then enqueue encoding and writing on a private serial DispatchQueue. The queued closure captures that immutable value. Create a JSONEncoder with `.iso8601` inside the queued write; catch and log encoding/write failures. No synchronous disk access in submit.
- [x] Implement idempotent shutdown: reject submissions, copy the last snapshot with state disconnected and fresh exportedAt, enter a DispatchGroup before enqueueing its write after prior writes, and leave the group in `defer` even on error. Retain the group so repeated shutdown calls wait on the same final operation rather than adding writes; completed waits do not consume a signal. Wait until `.now() + timeout`, log timeout, and return false if unfinished or failed. Store the write outcome on the writer queue and read it only after a successful group wait. The writer never needs the main thread to complete.
- [x] Add writer tests with temporary directories and injected closures. Verify FIFO replacement, complete JSON, newer timestamps for repeated percentages, recovery after an injected first-write failure, unchanged previous data on a real invalid-parent write, and rejection after shutdown. Use a gated writer plus a short test timeout to prove submit returns before disk work, shutdown returns on deadline, and repeated shutdown adds no second final write. Release the gate during cleanup so tests leave no blocked queue.
- [x] Run the tests, fix failures, and review the writer against every lifecycle requirement.

## Task 2: Lifecycle wiring and consumer documentation

**Files:** Modify `BatMon/Managers/BluetoothManager.swift`, `BatMon/App/AppDelegate.swift`, `README.md`; extend `BatMonTests/StatusExporterTests.swift`.

**Interfaces:** Uses StatusSnapshot and StatusExporter from Task 1. Adds
`Notification.Name.batMonWillTerminate` and a synchronous BluetoothManager handler.

- [x] In BluetoothManager retain one exporter. After loadSavedKeyboard, subscribe to the complete published tuple:

```swift
Publishers.CombineLatest3(
    $selectedKeyboard,
    $connectionState,
    PreferencesManager.shared.$settings.removeDuplicates {
        $0.pollingInterval == $1.pollingInterval &&
        $0.lowBatteryThreshold == $1.lowBatteryThreshold &&
        $0.criticalBatteryThreshold == $1.criticalBatteryThreshold
    }
)
.sink { [weak self] keyboard, state, settings in
    self?.statusExporter.submit(StatusSnapshot(keyboard: keyboard,
        connectionState: state, pollingIntervalSeconds: settings.pollingInterval,
        lowBatteryThreshold: settings.lowBatteryThreshold,
        criticalBatteryThreshold: settings.criticalBatteryThreshold))
}
.store(in: &cancellables)
```

  Consume the incoming values: @Published emits before property assignment.
  Do not deduplicate keyboard publications or add asynchronous delivery before
  snapshot construction. Existing callbacks and UI preference changes use the main thread.
- [x] Register the termination observer using the existing selector/NotificationCenter pattern. Its handler calls `statusExporter.shutdown()` synchronously. Post `.batMonWillTerminate` from AppDelegate.applicationWillTerminate before removing observers. Preserve the existing wake and reconnection behavior.
- [x] Extend contract/writer tests with initial, connected, threshold-change, disconnected, and forgotten-keyboard snapshots. Verify the recorded JSON retains publication order and exposes null readings after forgetting. Test the real snapshot constructor and writer rather than duplicating the app's subscription code in a fake manager. Inspect the actual Combine wiring for incoming-value capture, initial emission, and absence of keyboard deduplication; actual BLE callback delivery remains a hardware check.
- [x] Document the version-one JSON example, all nullable fields and state strings, both debug/release paths, timestamp semantics, freshness recommendation, and missing/malformed/version handling in README. Document stage one and directory watching for atomic replacements; watcher/events/panel remain follow-up work.
- [x] Run the complete test suite, app build, and diff whitespace check:

```sh
xcodebuild -project BatMon.xcodeproj -scheme BatMon -configuration Debug \
  -destination 'platform=macOS' -derivedDataPath /tmp/batmon-status-export \
  test CODE_SIGN_IDENTITY=-
xcodebuild -project BatMon.xcodeproj -scheme BatMon -configuration Debug \
  -destination 'platform=macOS' -derivedDataPath /tmp/batmon-status-export \
  build CODE_SIGN_IDENTITY=-
git diff --check
```

  If tool sandbox restrictions prevent Xcode from running, request the narrowly
  scoped execution escalation and report actual results. Do not replace a
  missing build result with a claimed success.
- [x] Review all newly changed sources and the final diff against the approved spec. Confirm existing local edits remain present and no sandbox entitlement or external process launch was introduced. Update this plan's checkboxes with completed verification.
- [x] Report the resulting consumer contract and build location. Leave installation, hardware BLE checks, and SketchyBar consumer verification explicitly pending. Do not commit pre-existing uncommitted changes as part of this feature.
