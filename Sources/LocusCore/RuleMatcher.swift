import Foundation

public enum RuleMatcher {
    public static func matchingRule(
        for ssid: String?,
        in rules: [WiFiRule],
        useFallback: Bool
    ) -> WiFiRule? {
        guard let ssid, !ssid.isEmpty else { return nil }

        if let exact = rules.first(where: {
            !$0.isFallback && $0.isEnabled && $0.ssid == ssid
        }) {
            return exact
        }

        guard useFallback else { return nil }
        return rules.first(where: { $0.isFallback && $0.isEnabled })
    }

    public static func normalizedSSID(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

public enum VolumeInterpolator {
    public static func values(
        from start: Double,
        to end: Double,
        duration: TimeInterval,
        framesPerSecond: Int = 30
    ) -> [Double] {
        let clampedStart = min(max(start, 0), 1)
        let clampedEnd = min(max(end, 0), 1)
        guard duration > 0, framesPerSecond > 0 else { return [clampedEnd] }

        let steps = max(Int(duration * Double(framesPerSecond)), 1)
        return (1...steps).map { index in
            let progress = Double(index) / Double(steps)
            let eased = 1 - pow(1 - progress, 3)
            return clampedStart + (clampedEnd - clampedStart) * eased
        }
    }
}
