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
}
