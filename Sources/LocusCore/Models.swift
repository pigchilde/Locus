import Foundation

public enum MutePolicy: String, Codable, CaseIterable, Identifiable, Sendable {
    case keep
    case unmute
    case mute

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .keep: return "保持当前状态"
        case .unmute: return "取消静音"
        case .mute: return "静音"
        }
    }
}

public enum VolumeTransition: String, Codable, CaseIterable, Identifiable, Sendable {
    case immediate
    case oneSecond
    case threeSeconds

    public var id: String { rawValue }

    public var duration: TimeInterval {
        switch self {
        case .immediate: return 0
        case .oneSecond: return 1
        case .threeSeconds: return 3
        }
    }

    public var displayName: String {
        switch self {
        case .immediate: return "立即调整"
        case .oneSecond: return "平滑调整 · 1 秒"
        case .threeSeconds: return "平滑调整 · 3 秒"
        }
    }
}

public enum AppearanceMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色"
        case .dark: return "深色"
        }
    }
}

public struct AudioOutputDevice: Codable, Hashable, Identifiable, Sendable {
    public var id: String { uid }
    public let uid: String
    public let name: String

    public init(uid: String, name: String) {
        self.uid = uid
        self.name = name
    }
}

public struct WiFiRule: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var ssid: String
    public var displayName: String
    public var outputDeviceUID: String?
    public var outputDeviceName: String?
    public var targetVolume: Double
    public var mutePolicy: MutePolicy
    public var transition: VolumeTransition
    public var showsNotification: Bool
    public var isEnabled: Bool
    public var isFallback: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        ssid: String,
        displayName: String? = nil,
        outputDeviceUID: String? = nil,
        outputDeviceName: String? = nil,
        targetVolume: Double,
        mutePolicy: MutePolicy = .keep,
        transition: VolumeTransition = .oneSecond,
        showsNotification: Bool = true,
        isEnabled: Bool = true,
        isFallback: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.ssid = ssid
        self.displayName = displayName ?? ssid
        self.outputDeviceUID = outputDeviceUID
        self.outputDeviceName = outputDeviceName
        self.targetVolume = min(max(targetVolume, 0), 1)
        self.mutePolicy = mutePolicy
        self.transition = transition
        self.showsNotification = showsNotification
        self.isEnabled = isEnabled
        self.isFallback = isFallback
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public static var defaultFallback: WiFiRule {
        WiFiRule(
            ssid: "__fallback__",
            displayName: "其他网络",
            targetVolume: 0.25,
            showsNotification: false,
            isEnabled: false,
            isFallback: true
        )
    }
}

public struct AppPreferences: Codable, Equatable, Sendable {
    public var automationEnabled: Bool
    public var launchAtLogin: Bool
    public var switchDelay: TimeInterval
    public var useFallbackRule: Bool
    public var appearance: AppearanceMode

    public init(
        automationEnabled: Bool = true,
        launchAtLogin: Bool = false,
        switchDelay: TimeInterval = 1,
        useFallbackRule: Bool = true,
        appearance: AppearanceMode = .system
    ) {
        self.automationEnabled = automationEnabled
        self.launchAtLogin = launchAtLogin
        self.switchDelay = switchDelay
        self.useFallbackRule = useFallbackRule
        self.appearance = appearance
    }

    private enum CodingKeys: String, CodingKey {
        case automationEnabled
        case launchAtLogin
        case switchDelay
        case useFallbackRule
        case appearance
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        automationEnabled = try container.decodeIfPresent(Bool.self, forKey: .automationEnabled) ?? true
        launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        switchDelay = try container.decodeIfPresent(TimeInterval.self, forKey: .switchDelay) ?? 1
        useFallbackRule = try container.decodeIfPresent(Bool.self, forKey: .useFallbackRule) ?? true
        appearance = try container.decodeIfPresent(AppearanceMode.self, forKey: .appearance) ?? .system
    }
}

public enum ActivityKind: String, Codable, Sendable {
    case ruleApplied
    case networkChanged
    case outputChanged
    case warning
}

public struct ActivityRecord: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var kind: ActivityKind
    public var title: String
    public var detail: String
    public var date: Date

    public init(
        id: UUID = UUID(),
        kind: ActivityKind,
        title: String,
        detail: String,
        date: Date = Date()
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.detail = detail
        self.date = date
    }
}

public struct PersistedState: Codable, Sendable {
    public var rules: [WiFiRule]
    public var preferences: AppPreferences
    public var activities: [ActivityRecord]

    public init(
        rules: [WiFiRule],
        preferences: AppPreferences,
        activities: [ActivityRecord]
    ) {
        self.rules = rules
        self.preferences = preferences
        self.activities = activities
    }
}
