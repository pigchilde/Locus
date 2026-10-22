import AppKit
import LocusCore
import SwiftUI

struct MenuBarHomeView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var permissions: PermissionService
    @EnvironmentObject private var router: PanelRouter

    var body: some View {
        VStack(spacing: 0) {
            MenuBarHeader(title: "Locus") {
                Button {
                    router.route = .settings
                } label: {
                    Image(systemName: "gearshape")
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
                .help("打开设置")
                .accessibilityLabel("打开设置")
            }

            ScrollView {
                VStack(alignment: .leading, spacing: LocusDesign.sectionSpacing) {
                    runtimeStatus
                    if model.needsWiFiPermission {
                        permissionNotice
                    }
                    environmentSection
                    audioSection
                    rulesSection
                    activitySection
                }
                .padding(.horizontal, LocusDesign.pagePadding)
                .padding(.vertical, 6)
            }
            .scrollIndicators(.hidden)

            automationFooter.padding(.horizontal, LocusDesign.pagePadding).padding(.bottom, 10)
        }
    }

    private var runtimeStatus: some View {
        HStack(spacing: 7) {
            Image(systemName: runtimeSymbol)
                .foregroundStyle(runtimeColor)
            Text(runtimeText)
                .font(.system(size: 11.5, weight: .medium))
            Spacer()
        }
        .padding(.horizontal, 12)
        .frame(height: 40)
        .background(Color.orange.opacity(0.075), in: RoundedRectangle(cornerRadius: LocusDesign.cardRadius))
        .accessibilityElement(children: .combine)
    }

    private var permissionNotice: some View {
        HStack(alignment: .center, spacing: 10) {
            LocusIconTile(symbol: "location.fill", color: .orange)
            VStack(alignment: .leading, spacing: 3) {
                Text("无法读取当前 Wi‑Fi")
                    .font(.system(size: 12, weight: .semibold))
                Text("macOS 需要位置权限才能提供网络名称。")
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Button(permissionButtonTitle) {
                if permissions.isDenied {
                    openLocationSettings()
                } else {
                    router.route = .permission
                }
            }
            .buttonStyle(LocusSecondaryButtonStyle())
            .disabled(permissions.isRequestingLocationPermission)
        }
        .padding(11)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: LocusDesign.cardRadius))
    }

    private var permissionButtonTitle: String {
        if permissions.isRequestingLocationPermission {
            return "等待系统…"
        }
        return permissions.isDenied ? "打开设置" : "允许"
    }

    private var environmentSection: some View {
        MenuBarSection(title: "当前环境") {
            LocusCard {
                if let destination = environmentDestination {
                    Button {
                        router.route = destination
                    } label: {
                        environmentRow
                    }
                    .buttonStyle(LocusRowButtonStyle())
                    .help(environmentActionTitle)
                    .accessibilityLabel("\(environmentName)，\(environmentActionTitle)")
                    .accessibilityHint("打开当前网络的规则设置")
                } else {
                    environmentRow
                }
            }
        }
    }

    private var environmentRow: some View {
        MenuBarRow(title: environmentName, subtitle: environmentSubtitle,
                   icon: model.currentNetwork?.kind.symbol ?? "network.slash") {
            if environmentDestination != nil {
                HStack(spacing: 5) {
                    Text(environmentActionTitle)
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(Color.accentColor)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private var currentEnvironmentRule: WiFiRule? {
        // Include disabled exact rules so this opens their settings instead of
        // attempting to add a duplicate or editing the shared fallback rule.
        model.rules.first { model.isCurrentNetwork($0) }
    }

    private var environmentDestination: PanelRoute? {
        if model.needsWiFiPermission { return .permission }
        guard model.currentNetwork?.identifier?.isEmpty == false else { return nil }
        return currentEnvironmentRule.map { .rule($0.id) } ?? .addRule
    }

    private var environmentActionTitle: String {
        if model.needsWiFiPermission { return "授权读取" }
        return currentEnvironmentRule == nil ? "添加规则" : "编辑规则"
    }

    private var audioSection: some View {
        MenuBarSection(title: "当前声音") {
            LocusCard {
                VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 7) {
                    LocusIconTile(symbol: model.currentMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    Text(model.currentDevice?.name ?? "未找到输出设备")
                        .font(.system(size: 12.5, weight: .medium))
                        .lineLimit(1)
                    Spacer()
                    Text(model.currentMuted ? "已静音" : "播放中")
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(minHeight: 36)

                HStack(spacing: 9) {
                    Image(systemName: model.currentMuted ? "speaker.slash" : "speaker.wave.2")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Slider(value: Binding(
                        get: { model.currentVolume },
                        set: model.setCurrentVolumeInteractively
                    ), in: 0...1)
                    Text(model.currentVolume, format: .percent.precision(.fractionLength(0)))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(width: 36, alignment: .trailing)
                }
                .padding(.bottom, 9)
                }
            }
        }
    }

    private var rulesSection: some View {
        MenuBarSection(title: "网络规则") {
            LocusCard {
                VStack(spacing: 0) {
                ForEach(Array(orderedRules.enumerated()), id: \.element.id) { index, rule in
                    if index > 0 { Divider() }
                    Button {
                        router.route = .rule(rule.id)
                    } label: {
                        ruleRow(rule)
                    }
                    .buttonStyle(LocusRowButtonStyle())
                }

                if !orderedRules.isEmpty { Divider() }
                Button {
                    router.route = .addRule
                } label: {
                    Label(addRuleTitle, systemImage: "plus")
                        .font(.system(size: 11.5, weight: .medium))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                }
                .buttonStyle(LocusRowButtonStyle())
                }
            }
        }
    }

    private func ruleRow(_ rule: WiFiRule) -> some View {
        HStack(spacing: 9) {
            LocusIconTile(symbol: ruleIcon(rule), color: isCurrentExact(rule) ? .accentColor : .secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(rule.displayName)
                    .font(.system(size: 12.5, weight: .medium))
                    .lineLimit(1)
                Text(ruleSubtitle(rule))
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Text(rule.targetVolume, format: .percent.precision(.fractionLength(0)))
                .font(.system(size: 10.5, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .frame(minHeight: LocusDesign.detailedRowHeight)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("打开规则详情")
    }

    @ViewBuilder
    private var activitySection: some View {
        if let activity = model.activities.first {
            MenuBarSection(title: "最近活动") {
                LocusCard { Button {
                    router.route = .activity
                } label: {
                    HStack(spacing: 9) {
                        LocusIconTile(symbol: activitySymbol(activity.kind))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(activity.title)
                                .font(.system(size: 11.5, weight: .medium))
                                .lineLimit(1)
                            Text(locusRelativeTime(from: activity.date))
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(LocusRowButtonStyle())
                }
            }
        }
    }

    private var automationFooter: some View {
        HStack(spacing: 10) {
            LocusIconTile(symbol: "waveform.path.ecg", color: .accentColor)
            VStack(alignment: .leading, spacing: 1) {
                Text("自动控制")
                    .font(.system(size: 12.5, weight: .medium))
                Text(model.preferences.automationEnabled ? "监听网络变化" : "当前不会自动应用规则")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("自动控制", isOn: Binding(
                get: { model.preferences.automationEnabled },
                set: model.setAutomationEnabled
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.small)
        }
        .padding(.horizontal, 11)
        .frame(height: 54)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: LocusDesign.cardRadius))
    }

    private var orderedRules: [WiFiRule] {
        model.rules.sorted { lhs, rhs in
            let left = sortRank(lhs)
            let right = sortRank(rhs)
            return left == right ? lhs.createdAt < rhs.createdAt : left < right
        }
    }

    private func sortRank(_ rule: WiFiRule) -> Int {
        if isCurrentExact(rule) { return 0 }
        if rule.isFallback { return 2 }
        return 1
    }

    private func isCurrentExact(_ rule: WiFiRule) -> Bool {
        model.isCurrentNetwork(rule)
    }

    private func ruleIcon(_ rule: WiFiRule) -> String {
        if rule.isFallback { return "globe" }
        return rule.kind.symbol
    }

    private func ruleSubtitle(_ rule: WiFiRule) -> String {
        guard rule.isEnabled else { return "已停用" }
        let device = rule.outputDeviceName ?? "保持当前设备"
        return "\(device) · \(rule.mutePolicy.displayName)"
    }

    private var addRuleTitle: String {
        guard let network = model.currentNetwork, network.identifier != nil else { return "添加网络规则" }
        let hasExact = model.rules.contains { model.isCurrentNetwork($0) }
        return hasExact ? "添加其他网络" : "为当前\(network.kind.displayName)添加规则"
    }

    private var environmentSubtitle: String {
        if let rule = model.matchingRule {
            return "\(rule.displayName) · 当前规则"
        }
        guard let network = model.currentNetwork else { return "等待 Wi‑Fi 或有线网络连接" }
        if model.needsWiFiPermission { return "需要位置权限才能读取 Wi‑Fi 名称" }
        if network.identifier == nil { return "等待网络信息就绪" }
        return network.detail.isEmpty ? "尚未创建规则" : network.detail
    }

    private var environmentName: String {
        model.currentNetwork?.name ?? "未连接可识别的网络"
    }

    private var runtimeText: String {
        switch model.runtimeState {
        case .applying(let name): return "正在应用“\(name)”"
        case .ready: return model.matchingRule == nil ? "自动控制已开启" : "当前规则已应用"
        case .error: return "操作未完成"
        default: return model.runtimeState.shortLabel
        }
    }

    private var runtimeSymbol: String {
        switch model.runtimeState {
        case .ready: return "checkmark.circle.fill"
        case .applying, .starting: return "arrow.triangle.2.circlepath"
        case .paused: return "pause.circle.fill"
        case .noMatchingRule: return "questionmark.circle"
        case .disconnected: return "network.slash"
        case .waitingForPermission, .error: return "exclamationmark.triangle.fill"
        }
    }

    private var runtimeColor: Color {
        switch model.runtimeState {
        case .ready: return .green
        case .applying, .starting: return .accentColor
        case .paused, .disconnected: return .secondary
        case .noMatchingRule, .waitingForPermission: return .orange
        case .error: return .red
        }
    }

    private func activitySymbol(_ kind: ActivityKind) -> String {
        switch kind {
        case .ruleApplied: return "checkmark.circle"
        case .networkChanged: return "network"
        case .outputChanged: return "speaker.wave.2"
        case .warning: return "exclamationmark.triangle"
        }
    }

    private func openLocationSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") else { return }
        NSWorkspace.shared.open(url)
    }
}
