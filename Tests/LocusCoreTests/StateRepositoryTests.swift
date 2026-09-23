import Foundation
import XCTest
@testable import LocusCore

final class StateRepositoryTests: XCTestCase {
    func testStateRoundTripPreservesRulesAndPreferences() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = StateRepository(
            fileURL: root.appendingPathComponent("state.json")
        )
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let rule = WiFiRule(
            ssid: "Home",
            outputDeviceUID: "device-1",
            outputDeviceName: "MacBook 扬声器",
            targetVolume: 0.32,
            mutePolicy: .unmute,
            transition: .threeSeconds,
            createdAt: fixedDate,
            updatedAt: fixedDate
        )
        let state = PersistedState(
            rules: [rule],
            preferences: AppPreferences(
                automationEnabled: true,
                launchAtLogin: true,
                switchDelay: 3,
                useFallbackRule: false,
                appearance: .dark
            ),
            activities: [ActivityRecord(
                kind: .ruleApplied,
                title: "已应用 Home",
                detail: "系统音量已调整至 32%",
                date: fixedDate
            )]
        )

        try repository.save(state)
        let loaded = try XCTUnwrap(repository.load())

        XCTAssertEqual(loaded.rules, state.rules)
        XCTAssertEqual(loaded.preferences, state.preferences)
        XCTAssertEqual(loaded.activities.count, 1)
        XCTAssertEqual(loaded.activities[0].id, state.activities[0].id)
        XCTAssertEqual(loaded.activities[0].kind, state.activities[0].kind)
        XCTAssertEqual(loaded.activities[0].title, state.activities[0].title)
        XCTAssertEqual(loaded.activities[0].detail, state.activities[0].detail)
        XCTAssertEqual(
            loaded.activities[0].date.timeIntervalSince1970,
            state.activities[0].date.timeIntervalSince1970,
            accuracy: 0.000_001
        )
    }

    func testOlderPreferencesDefaultToSystemAppearance() throws {
        let data = Data("""
        {
          "automationEnabled": true,
          "launchAtLogin": false,
          "showMenuBar": true,
          "switchDelay": 1,
          "useFallbackRule": true
        }
        """.utf8)

        let preferences = try JSONDecoder().decode(AppPreferences.self, from: data)

        XCTAssertEqual(preferences.appearance, .system)
    }

    func testLegacyShowMenuBarFieldIsIgnored() throws {
        let data = Data("""
        {
          "automationEnabled": true,
          "launchAtLogin": true,
          "showMenuBar": false,
          "switchDelay": 3,
          "useFallbackRule": false,
          "appearance": "dark"
        }
        """.utf8)

        let preferences = try JSONDecoder().decode(AppPreferences.self, from: data)

        XCTAssertTrue(preferences.automationEnabled)
        XCTAssertTrue(preferences.launchAtLogin)
        XCTAssertEqual(preferences.switchDelay, 3)
        XCTAssertFalse(preferences.useFallbackRule)
        XCTAssertEqual(preferences.appearance, .dark)
    }
}
