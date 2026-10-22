import AppKit
import XCTest
import LocusCore
@testable import LocusApp

final class PreviewWorkflowTests: XCTestCase {
    @MainActor
    private func makeModel(_ scenario: String = "ready") throws -> (AppModel, StateRepository, URL) {
        _ = NSApplication.shared
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("LocusUITest-\(UUID().uuidString).json")
        let repository = StateRepository(fileURL: url)
        let preview = LocusPreviewState(scenario: scenario)
        try repository.save(preview.persisted)
        let model = AppModel(repository: repository, preview: preview)
        model.start()
        return (model, repository, url)
    }

    @MainActor
    func testNewWiFiCanBeSavedEditedAndDeletedWithoutLosingNetworkContext() throws {
        let (model, repository, url) = try makeModel("newWiFi")
        defer { try? FileManager.default.removeItem(at: url) }
        XCTAssertEqual(model.runtimeState, .noMatchingRule)
        let network = try XCTUnwrap(model.currentNetwork)
        XCTAssertEqual(network.name, "Studio Wi-Fi")
        var rule = try XCTUnwrap(model.addRule(ssid: try XCTUnwrap(network.identifier), volume: 0.35, outputDeviceUID: nil))
        XCTAssertTrue(model.isCurrentNetwork(rule))
        XCTAssertNotEqual(model.lastAppliedRule?.id, rule.id, "Saving a rule must not claim that it has been applied")
        rule.targetVolume = 0.6
        model.updateRule(rule)
        XCTAssertEqual(try XCTUnwrap(repository.load()).rules.first { $0.id == rule.id }?.targetVolume, 0.6)
        model.deleteRule(id: rule.id)
        XCTAssertNil(model.rule(withID: rule.id))
        XCTAssertEqual(model.currentNetwork, network)
        XCTAssertFalse(try XCTUnwrap(repository.load()).rules.contains { $0.id == rule.id })
    }

    @MainActor
    func testNewEthernetRuleKeepsStableIdentifierAndReadableName() throws {
        let (model, _, url) = try makeModel("newEthernet")
        defer { try? FileManager.default.removeItem(at: url) }
        let network = try XCTUnwrap(model.currentNetwork)
        let rule = try XCTUnwrap(model.addRule(ssid: try XCTUnwrap(network.identifier), networkKind: .ethernet,
                                             displayName: "工作室", volume: 0.2, outputDeviceUID: nil))
        XCTAssertEqual(rule.displayName, "工作室")
        XCTAssertTrue(model.isCurrentNetwork(rule))
        XCTAssertEqual(rule.kind, .ethernet)
        XCTAssertEqual(rule.ssid, "preview-new-office")
    }

    @MainActor
    func testFallbackCannotBeDeletedAndDuplicateDoesNotCreateExtraRule() throws {
        let (model, _, url) = try makeModel()
        defer { try? FileManager.default.removeItem(at: url) }
        let fallback = try XCTUnwrap(model.rules.first { $0.isFallback })
        model.deleteRule(id: fallback.id)
        XCTAssertNotNil(model.rule(withID: fallback.id))
        let count = model.rules.count
        model.addRule(ssid: "preview-office", networkKind: .ethernet, volume: 0.7, outputDeviceUID: nil)
        XCTAssertEqual(model.rules.count, count)
        XCTAssertNotNil(model.lastErrorMessage)
    }

    @MainActor
    func testRenamingDisconnectedWiFiPreservesMatchingIdentityAndSavedName() throws {
        let (model, repository, url) = try makeModel()
        defer { try? FileManager.default.removeItem(at: url) }
        var rule = try XCTUnwrap(model.rules.first { $0.kind == .wifi && !$0.isFallback })
        XCTAssertFalse(model.isCurrentNetwork(rule))
        let identifier = rule.ssid
        rule.displayName = "公司无线网络"
        model.updateRule(rule)
        let saved = try XCTUnwrap(repository.load())
        let restored = try XCTUnwrap(saved.rules.first { $0.id == rule.id })
        XCTAssertEqual(restored.displayName, "公司无线网络")
        XCTAssertEqual(restored.ssid, identifier)
        let matching = RuleMatcher.matchingRule(for: identifier, kind: .wifi, in: saved.rules, useFallback: false)
        XCTAssertEqual(matching?.id, rule.id)
        XCTAssertEqual(matching?.displayName, "公司无线网络")
    }

    @MainActor
    func testPreviewControlsStayOnSimulatedSnapshot() throws {
        let (model, _, url) = try makeModel()
        defer { try? FileManager.default.removeItem(at: url) }
        model.setCurrentMutedInteractively(false)
        model.setCurrentVolumeInteractively(0.65)
        model.refreshSnapshot()
        model.refreshAudioState()
        XCTAssertEqual(model.currentVolume, 0.65)
        XCTAssertFalse(model.currentMuted)
        XCTAssertEqual(model.currentDevice?.uid, "preview-speakers")
        model.setAutomationEnabled(false)
        guard case .paused = model.runtimeState else { return XCTFail("Automation should be paused") }
        model.setAutomationEnabled(true)
        XCTAssertEqual(model.runtimeState, .ready)
        XCTAssertEqual(model.currentVolume, 0.65)
    }
}
