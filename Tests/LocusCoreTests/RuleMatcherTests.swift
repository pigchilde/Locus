import XCTest
@testable import LocusCore

final class RuleMatcherTests: XCTestCase {
    func testExactEnabledRuleWinsOverFallback() {
        let exact = WiFiRule(ssid: "Studio", targetVolume: 0.42)
        let fallback = WiFiRule(
            ssid: "__fallback__",
            displayName: "其他网络",
            targetVolume: 0.2,
            isFallback: true
        )

        let result = RuleMatcher.matchingRule(
            for: "Studio",
            in: [fallback, exact],
            useFallback: true
        )

        XCTAssertEqual(result?.id, exact.id)
    }

    func testDisabledExactRuleFallsBack() {
        let disabled = WiFiRule(
            ssid: "Studio",
            targetVolume: 0.42,
            isEnabled: false
        )
        let fallback = WiFiRule(
            ssid: "__fallback__",
            displayName: "其他网络",
            targetVolume: 0.2,
            isFallback: true
        )

        let result = RuleMatcher.matchingRule(
            for: "Studio",
            in: [disabled, fallback],
            useFallback: true
        )

        XCTAssertEqual(result?.id, fallback.id)
    }

    func testFallbackCanBeDisabledGlobally() {
        let fallback = WiFiRule(
            ssid: "__fallback__",
            displayName: "其他网络",
            targetVolume: 0.2,
            isFallback: true
        )

        XCTAssertNil(RuleMatcher.matchingRule(
            for: "Unknown",
            in: [fallback],
            useFallback: false
        ))
    }

    func testMissingSSIDNeverUsesFallback() {
        let fallback = WiFiRule(
            ssid: "__fallback__",
            displayName: "其他网络",
            targetVolume: 0.2,
            isFallback: true
        )

        XCTAssertNil(RuleMatcher.matchingRule(
            for: nil,
            in: [fallback],
            useFallback: true
        ))
    }

    func testSSIDNormalization() {
        XCTAssertEqual(RuleMatcher.normalizedSSID("  Home 5G\n"), "Home 5G")
    }

    func testEthernetRuleWinsOverWiFiWithTheSameIdentifier() {
        let wifi = WiFiRule(ssid: "shared", targetVolume: 0.8)
        let wired = WiFiRule(ssid: "shared", networkKind: .ethernet, targetVolume: 0.2)
        XCTAssertEqual(RuleMatcher.matchingRule(for: "shared", kind: .ethernet,
            in: [wifi, wired], useFallback: true)?.id, wired.id)
        XCTAssertEqual(RuleMatcher.matchingRule(for: "shared",
            in: [wired, wifi], useFallback: true)?.id, wifi.id)
    }

    func testUnrecognizedWiredNetworkUsesEnabledFallback() {
        var fallback = WiFiRule.defaultFallback
        fallback.isEnabled = true
        let disabled = WiFiRule(ssid: "office", networkKind: .ethernet,
            targetVolume: 0.4, isEnabled: false)
        XCTAssertEqual(RuleMatcher.matchingRule(for: "office", kind: .ethernet,
            in: [disabled, fallback], useFallback: true)?.id, fallback.id)
        XCTAssertNil(RuleMatcher.matchingRule(for: "office", kind: .ethernet,
            in: [fallback], useFallback: false))
        XCTAssertNil(RuleMatcher.matchingRule(for: nil, kind: .ethernet,
            in: [fallback], useFallback: true))
    }

    func testSwitchingFromWiredToWiFiSelectsTheOtherRule() {
        let wifi = WiFiRule(ssid: "Studio", targetVolume: 0.6)
        let wired = WiFiRule(ssid: "office", networkKind: .ethernet, targetVolume: 0.1)
        let rules = [wifi, wired]
        XCTAssertEqual(RuleMatcher.matchingRule(for: "office", kind: .ethernet,
            in: rules, useFallback: false)?.id, wired.id)
        XCTAssertEqual(RuleMatcher.matchingRule(for: "Studio", kind: .wifi,
            in: rules, useFallback: false)?.id, wifi.id)
    }
}
