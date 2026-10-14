import Foundation
import XCTest

final class PreferencesMigrationTests: XCTestCase {
    func testEmptyDomainImportsLegacyPreferencesOnlyOnce() throws {
        let legacyName = UUID().uuidString
        let currentName = UUID().uuidString
        let legacy = try XCTUnwrap(UserDefaults(suiteName: legacyName))
        let current = try XCTUnwrap(UserDefaults(suiteName: currentName))
        defer {
            legacy.removePersistentDomain(forName: legacyName)
            current.removePersistentDomain(forName: currentName)
        }
        let settings = Data("saved settings".utf8)
        let keyboard = Data("saved keyboard".utf8)
        legacy.set(settings, forKey: UserDefaultsKeys.appSettings)
        legacy.set(keyboard, forKey: UserDefaultsKeys.selectedKeyboardData)
        legacy.set(Data("saved keyboards".utf8), forKey: UserDefaultsKeys.savedKeyboards)
        legacy.set(true, forKey: UserDefaultsKeys.hasCompletedSetup)
        legacy.set("unrelated", forKey: "widgetThemeId")
        PreferencesMigration.migrate(from: legacy, to: current)
        XCTAssertEqual(current.data(forKey: UserDefaultsKeys.appSettings), settings)
        XCTAssertEqual(current.data(forKey: UserDefaultsKeys.selectedKeyboardData), keyboard)
        XCTAssertEqual(current.data(forKey: UserDefaultsKeys.savedKeyboards), Data("saved keyboards".utf8))
        XCTAssertTrue(current.bool(forKey: UserDefaultsKeys.hasCompletedSetup))
        XCTAssertNil(current.object(forKey: "widgetThemeId"))
        current.removeObject(forKey: UserDefaultsKeys.selectedKeyboardData)
        PreferencesMigration.migrate(from: legacy, to: current)
        XCTAssertNil(current.object(forKey: UserDefaultsKeys.selectedKeyboardData))
    }

    func testEstablishedDomainDoesNotRestoreOldKeyboard() throws {
        let legacyName = UUID().uuidString
        let currentName = UUID().uuidString
        let legacy = try XCTUnwrap(UserDefaults(suiteName: legacyName))
        let current = try XCTUnwrap(UserDefaults(suiteName: currentName))
        defer {
            legacy.removePersistentDomain(forName: legacyName)
            current.removePersistentDomain(forName: currentName)
        }
        legacy.set(Data("old keyboard".utf8), forKey: UserDefaultsKeys.selectedKeyboardData)
        legacy.set(true, forKey: UserDefaultsKeys.hasCompletedSetup)
        current.set(false, forKey: UserDefaultsKeys.hasCompletedSetup)
        PreferencesMigration.migrate(from: legacy, to: current)
        XCTAssertFalse(current.bool(forKey: UserDefaultsKeys.hasCompletedSetup))
        XCTAssertNil(current.object(forKey: UserDefaultsKeys.selectedKeyboardData))
    }
}

final class RunScriptTests: XCTestCase {
    func testInvalidArgumentDoesNotBuildOrStopAnApp() throws {
        let result = try runScript(argument: "invalid")
        XCTAssertEqual(result.status, 2)
        XCTAssertFalse(result.built)
        XCTAssertFalse(result.stopped)
    }

    func testFailedBuildDoesNotStopAnApp() throws {
        let result = try runScript(argument: "run")
        XCTAssertEqual(result.status, 42)
        XCTAssertTrue(result.built)
        XCTAssertFalse(result.stopped)
    }

    func testSuccessfulBuildQuitsOnlyTheLocalApp() throws {
        let result = try runScript(argument: "debug", buildExit: 0)
        XCTAssertEqual(result.status, 0)
        XCTAssertTrue(result.built)
        XCTAssertTrue(result.quitCommand?.contains("com.paolo.bat-mon.local") == true)
        XCTAssertFalse(result.quitCommand?.contains("com.paolo.bat-mon\"") == true)
    }

    private func runScript(argument: String, buildExit: Int = 42) throws -> (status: Int32, built: Bool, stopped: Bool, quitCommand: String?) {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        for (name, contents) in [
            "xcodebuild": "#!/bin/bash\ntouch \"$BATMON_SCRIPT_TEST_DIR/built\"\nexit \"$BATMON_SCRIPT_TEST_BUILD_EXIT\"\n",
            "pkill": "#!/bin/bash\ntouch \"$BATMON_SCRIPT_TEST_DIR/stopped\"\n",
            "osascript": "#!/bin/bash\ntouch \"$BATMON_SCRIPT_TEST_DIR/stopped\"\nprintf '%s' \"$*\" > \"$BATMON_SCRIPT_TEST_DIR/quit-command\"\n",
            "lldb": "#!/bin/bash\nexit 0\n"
        ] {
            let file = directory.appendingPathComponent(name)
            try contents.write(to: file, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: file.path)
        }
        let script = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent().appendingPathComponent("script/build_and_run.sh")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [script.path, argument]
        var environment = ProcessInfo.processInfo.environment
        environment["PATH"] = "\(directory.path):/usr/bin:/bin"
        environment["BATMON_SCRIPT_TEST_DIR"] = directory.path
        environment["BATMON_SCRIPT_TEST_BUILD_EXIT"] = String(buildExit)
        process.environment = environment
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        return (process.terminationStatus,
                FileManager.default.fileExists(atPath: directory.appendingPathComponent("built").path),
                FileManager.default.fileExists(atPath: directory.appendingPathComponent("stopped").path),
                try? String(contentsOf: directory.appendingPathComponent("quit-command"), encoding: .utf8))
    }
}
