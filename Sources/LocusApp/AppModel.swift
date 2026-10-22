import AppKit
import Combine
import CoreLocation
import Foundation
import LocusCore
import UserNotifications

@MainActor
final class AppModel: ObservableObject {
    enum RuntimeState: Equatable {
        case starting
        case ready
        case waitingForPermission
        case paused(Date)
        case applying(String)
        case noMatchingRule
        case disconnected
        case error(String)

        var shortLabel: String {
            switch self {
            case .starting: return "正在启动"
            case .ready: return "自动控制已开启"
            case .waitingForPermission: return "需要位置权限"
            case .paused: return "自动控制已暂停"
            case .applying: return "正在应用规则"
            case .noMatchingRule: return "当前网络没有规则"
            case .disconnected: return "未连接可识别的网络"
            case .error: return "需要处理"
            }
        }
    }

    @Published private(set) var rules: [WiFiRule]
    @Published private(set) var preferences: AppPreferences
    @Published private(set) var activities: [ActivityRecord]
    @Published private(set) var currentNetwork: NetworkConnection?
    @Published private(set) var currentVolume: Double = 0
    @Published private(set) var currentMuted = false
    @Published private(set) var currentDevice: AudioOutputDevice?
    @Published private(set) var availableDevices: [AudioOutputDevice] = []
    @Published private(set) var runtimeState: RuntimeState = .starting
    @Published private(set) var notificationAuthorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var lastErrorMessage: String?

    let permissions: PermissionService

    private let repository: StateRepository
    private let audio: CoreAudioService
    private let network: NetworkService
    private let notifications: NotificationService
    private var networkTask: Task<Void, Never>?
    private var volumeTask: Task<Void, Never>?
    private var interactiveVolumeTask: Task<Void, Never>?
    private var pausedUntil: Date?
    private var hasObservedNetwork = false
    private var hasStarted = false

    init(
        repository: StateRepository = StateRepository(),
        audio: CoreAudioService = CoreAudioService(),
        network: NetworkService = NetworkService(),
        permissions: PermissionService = PermissionService(),
        notifications: NotificationService = NotificationService()
    ) {
        self.repository = repository
        self.audio = audio
        self.network = network
        self.permissions = permissions
        self.notifications = notifications

        if let persisted = try? repository.load() {
            rules = persisted.rules
            preferences = persisted.preferences
            activities = persisted.activities
        } else {
            rules = [.defaultFallback]
            preferences = AppPreferences()
            activities = []
        }

        self.permissions.onAuthorizationChanged = { [weak self] in
            Task { @MainActor in
                self?.restartNetworkMonitoring()
            }
        }
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        applyAppearance()
        refreshAudioState()
        restartNetworkMonitoring()
        Task { await refreshNotificationAuthorizationStatus() }
        preferences.launchAtLogin = LaunchAtLoginService.isEnabled
        persist()
    }

    func restartNetworkMonitoring() {
        do {
            try network.startMonitoring { [weak self] connection in
                // NetworkService delivers on the main queue, including its initial snapshot.
                self?.handleNetworkChange(connection)
            }
        } catch {
            report(error)
        }
    }

    /// Refresh the panel without reapplying an unchanged network rule.
    func refreshSnapshot() {
        refreshAudioState()
        handleNetworkChange(network.currentConnection, recordActivity: false)
    }

    var needsWiFiPermission: Bool {
        currentNetwork?.kind == .wifi && currentNetwork?.identifier == nil && !permissions.canReadWiFiName
    }

    func isCurrentNetwork(_ rule: WiFiRule) -> Bool {
        guard !rule.isFallback, let currentNetwork, let identifier = currentNetwork.identifier else { return false }
        return rule.kind == currentNetwork.kind && rule.ssid == identifier
    }

    func refreshAudioState() {
        do {
            currentVolume = try audio.currentVolume()
            currentMuted = try audio.isMuted()
            currentDevice = try audio.currentOutputDevice()
            availableDevices = try audio.outputDevices()
        } catch {
            report(error)
        }
    }

    func requestLocationPermission() {
        permissions.requestLocationPermission()
    }

    func requestNotificationPermission() async -> Bool {
        let granted = await notifications.requestAuthorization()
        await refreshNotificationAuthorizationStatus()
        return granted
    }

    func refreshNotificationAuthorizationStatus() async {
        notificationAuthorizationStatus = await notifications.authorizationStatus()
    }

    func rule(withID id: UUID?) -> WiFiRule? {
        guard let id else { return nil }
        return rules.first(where: { $0.id == id })
    }

    func updateRule(_ updated: WiFiRule) {
        guard let index = rules.firstIndex(where: { $0.id == updated.id }) else { return }
        var copy = updated
        copy.targetVolume = min(max(copy.targetVolume, 0), 1)
        copy.updatedAt = Date()
        rules[index] = copy
        persist()
    }

    @discardableResult
    func addRule(
        ssid rawSSID: String,
        networkKind: NetworkKind = .wifi,
        displayName: String? = nil,
        volume: Double,
        outputDeviceUID: String?
    ) -> WiFiRule? {
        let ssid = networkKind == .wifi ? RuleMatcher.normalizedSSID(rawSSID) : rawSSID
        guard !ssid.isEmpty else {
            lastErrorMessage = "无法识别网络，请等待网络连接稳定后再试。"
            return nil
        }

        if let existing = rules.first(where: { !$0.isFallback && $0.kind == networkKind && $0.ssid == ssid }) {
            lastErrorMessage = "这个网络已经有一条规则。"
            return existing
        }

        let selectedDevice = availableDevices.first(where: { $0.uid == outputDeviceUID })
        let rule = WiFiRule(
            ssid: ssid,
            networkKind: networkKind,
            displayName: displayName,
            outputDeviceUID: selectedDevice?.uid,
            outputDeviceName: selectedDevice?.name,
            targetVolume: volume
        )
        let fallbackIndex = rules.firstIndex(where: { $0.isFallback }) ?? rules.endIndex
        rules.insert(rule, at: fallbackIndex)
        persist()
        return rule
    }

    func deleteRule(id: UUID) {
        guard let rule = rules.first(where: { $0.id == id }), !rule.isFallback else { return }
        rules.removeAll(where: { $0.id == id })
        persist()
    }

    func setAutomationEnabled(_ enabled: Bool) {
        guard preferences.automationEnabled != enabled else { return }
        preferences.automationEnabled = enabled
        if enabled {
            scheduleMatchingRuleApplication()
        } else {
            networkTask?.cancel()
            volumeTask?.cancel()
            runtimeState = .paused(.distantFuture)
        }
        persist()
    }

    func setSwitchDelay(_ delay: TimeInterval) {
        let normalized = max(delay, 0)
        guard preferences.switchDelay != normalized else { return }
        preferences.switchDelay = normalized
        persist()
    }

    func setUseFallback(_ enabled: Bool) {
        guard preferences.useFallbackRule != enabled else { return }
        preferences.useFallbackRule = enabled
        persist()
        scheduleMatchingRuleApplication()
    }

    func setAppearance(_ appearance: AppearanceMode) {
        guard preferences.appearance != appearance else { return }
        preferences.appearance = appearance
        applyAppearance()
        persist()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        guard preferences.launchAtLogin != enabled else { return }
        do {
            try LaunchAtLoginService.setEnabled(enabled)
            preferences.launchAtLogin = LaunchAtLoginService.isEnabled
            persist()
        } catch {
            preferences.launchAtLogin = LaunchAtLoginService.isEnabled
            report(error)
        }
    }

    func setCurrentVolumeInteractively(_ value: Double) {
        let normalized = min(max(value, 0), 1)
        currentVolume = normalized
        interactiveVolumeTask?.cancel()
        interactiveVolumeTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(40))
            guard !Task.isCancelled, let self else { return }
            do {
                try audio.setVolume(normalized)
            } catch {
                report(error)
            }
        }
    }

    func applyRuleNow(_ rule: WiFiRule) {
        volumeTask?.cancel()
        volumeTask = Task { @MainActor [weak self] in
            await self?.apply(rule)
        }
    }

    func pause(for interval: TimeInterval) {
        let date = Date().addingTimeInterval(interval)
        pausedUntil = date
        networkTask?.cancel()
        volumeTask?.cancel()
        runtimeState = .paused(date)
    }

    func resumeAutomation() {
        pausedUntil = nil
        runtimeState = .ready
        scheduleMatchingRuleApplication()
    }

    var matchingRule: WiFiRule? {
        RuleMatcher.matchingRule(
            for: currentNetwork?.identifier,
            kind: currentNetwork?.kind ?? .wifi,
            in: rules,
            useFallback: preferences.useFallbackRule
        )
    }

    var isPaused: Bool {
        guard let pausedUntil else { return false }
        return pausedUntil > Date()
    }

    private func handleNetworkChange(_ connection: NetworkConnection?, recordActivity: Bool = true) {
        let previous = currentNetwork
        currentNetwork = connection
        // Interface labels/address updates do not reapply an unchanged rule.
        let changed = !hasObservedNetwork || previous?.kind != connection?.kind
            || previous?.identifier != connection?.identifier
        hasObservedNetwork = true
        guard changed else {
            if runtimeState == .waitingForPermission { scheduleMatchingRuleApplication() }
            return
        }
        networkTask?.cancel()
        volumeTask?.cancel()
        if recordActivity {
            appendActivity(ActivityRecord(
                kind: .networkChanged,
                title: connection.map { "已连接 \($0.name)" } ?? "网络已断开",
                detail: connection.flatMap { $0.detail.isEmpty ? nil : $0.detail } ?? "正在更新声音规则"
            ))
        }
        scheduleMatchingRuleApplication()
    }

    private func scheduleMatchingRuleApplication() {
        networkTask?.cancel()

        guard preferences.automationEnabled else {
            runtimeState = .paused(.distantFuture)
            return
        }
        if let pausedUntil, pausedUntil > Date() {
            runtimeState = .paused(pausedUntil)
            return
        }
        pausedUntil = nil

        guard currentNetwork != nil else {
            runtimeState = .disconnected
            return
        }
        guard !needsWiFiPermission else {
            runtimeState = .waitingForPermission
            return
        }
        guard let rule = matchingRule else {
            runtimeState = .noMatchingRule
            return
        }

        let delay = preferences.switchDelay
        networkTask = Task { @MainActor [weak self] in
            if delay > 0 {
                try? await Task.sleep(for: .seconds(delay))
            }
            guard !Task.isCancelled else { return }
            await self?.apply(rule)
        }
    }

    private func apply(_ rule: WiFiRule) async {
        guard rule.isEnabled else { return }
        runtimeState = .applying(rule.displayName)

        do {
            if let uid = rule.outputDeviceUID,
               currentDevice?.uid != uid {
                try audio.setOutputDevice(uid: uid)
                try? await Task.sleep(for: .milliseconds(250))
                try Task.checkCancellation()
                currentDevice = try audio.currentOutputDevice()
                availableDevices = try audio.outputDevices()
            }

            let startVolume = try audio.currentVolume()
            let values = VolumeInterpolator.values(
                from: startVolume,
                to: rule.targetVolume,
                duration: rule.transition.duration
            )
            let stepDelay = rule.transition.duration > 0
                ? rule.transition.duration / Double(max(values.count, 1))
                : 0

            for value in values {
                guard !Task.isCancelled else { return }
                try audio.setVolume(value)
                currentVolume = value
                if stepDelay > 0 {
                    try? await Task.sleep(for: .seconds(stepDelay))
                }
            }

            try Task.checkCancellation()
            switch rule.mutePolicy {
            case .keep: break
            case .unmute: try audio.setMuted(false)
            case .mute: try audio.setMuted(true)
            }

            currentVolume = try audio.currentVolume()
            currentMuted = try audio.isMuted()
            currentDevice = try audio.currentOutputDevice()
            runtimeState = .ready
            appendActivity(ActivityRecord(
                kind: .ruleApplied,
                title: "已应用 \(rule.displayName)",
                detail: "系统音量已调整至 \(Int((rule.targetVolume * 100).rounded()))%"
            ))

            if rule.showsNotification {
                notifications.postRuleApplied(
                    ssid: currentNetwork?.name ?? rule.displayName,
                    volume: rule.targetVolume
                )
            }
        } catch is CancellationError {
            return
        } catch {
            report(error)
        }
    }

    private func appendActivity(_ activity: ActivityRecord) {
        activities.insert(activity, at: 0)
        activities = Array(activities.prefix(50))
        persist()
    }

    private func persist() {
        do {
            try repository.save(PersistedState(
                rules: rules,
                preferences: preferences,
                activities: activities
            ))
        } catch {
            lastErrorMessage = "保存设置失败：\(error.localizedDescription)"
        }
    }

    private func applyAppearance() {
        switch preferences.appearance {
        case .system:
            NSApp.appearance = nil
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }

    private func report(_ error: Error) {
        let message = error.localizedDescription
        lastErrorMessage = message
        runtimeState = .error(message)
        appendActivity(ActivityRecord(
            kind: .warning,
            title: "操作未完成",
            detail: message
        ))
    }
}
