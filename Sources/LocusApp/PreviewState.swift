import Foundation
import LocusCore

/// Deterministic, disposable data for native UI verification. No hardware is used.
struct LocusPreviewState {
    let scenario: String
    var network: NetworkConnection? {
        switch scenario {
        case "disconnected": return nil
        case "newWiFi": return NetworkConnection(kind: .wifi, identifier: "Studio Wi-Fi", name: "Studio Wi-Fi", interfaceName: "en0")
        case "permission": return NetworkConnection(kind: .wifi, identifier: nil, name: "Wi-Fi", interfaceName: "en0")
        case "newEthernet": return NetworkConnection(kind: .ethernet, identifier: "preview-new-office", name: "有线网络", interfaceName: "en9", detail: "网关 192.168.1.1 · en9")
        default: return NetworkConnection(kind: .ethernet, identifier: "preview-office", name: "有线网络", interfaceName: "en9", detail: "网关 192.168.1.1 · en9")
        }
    }

    var persisted: PersistedState {
        let now = Date()
        var rules = [
            WiFiRule(ssid: "preview-office", networkKind: .ethernet, displayName: "办公室有线网络", targetVolume: 0),
            WiFiRule(ssid: "NetDragon-FZ", targetVolume: 0, mutePolicy: .mute),
            WiFiRule(ssid: "HOME_Wi-Fi5", targetVolume: 0.26),
            WiFiRule(ssid: "HOME", targetVolume: 0.3),
            .defaultFallback
        ]
        if scenario == "missingDevice" {
            rules[0].outputDeviceUID = "preview-unavailable"
            rules[0].outputDeviceName = "会议室扬声器"
        }
        if scenario == "longName" {
            rules[0].displayName = "办公室有线网络 · 研发中心三楼东侧会议室"
        }
        if scenario == "manyRules" {
            rules.insert(contentsOf: (1...10).map { WiFiRule(ssid: "Studio-\($0)", targetVolume: 0.35) }, at: 4)
        }
        return PersistedState(
            rules: rules,
            preferences: AppPreferences(automationEnabled: scenario != "paused", switchDelay: 1),
            activities: scenario == "emptyActivity" ? [] : [
                ActivityRecord(kind: .ruleApplied, title: "已应用办公室有线网络", detail: "系统音量已调整至 0%", date: now.addingTimeInterval(-2040)),
                ActivityRecord(kind: .networkChanged, title: "已连接有线网络", detail: "网关 192.168.1.1 · en9", date: now.addingTimeInterval(-2043)),
                ActivityRecord(kind: .outputChanged, title: "输出设备已切换", detail: "MacBook Pro 扬声器", date: now.addingTimeInterval(-3600)),
                ActivityRecord(kind: .warning, title: "操作未完成", detail: "目标音频设备当前不可用", date: now.addingTimeInterval(-86400))
            ]
        )
    }
}
