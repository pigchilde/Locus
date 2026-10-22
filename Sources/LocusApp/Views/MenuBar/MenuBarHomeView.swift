import LocusCore
import SwiftUI

struct MenuBarHomeView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var router: PanelRouter

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    environmentSection
                    audioSection
                    rulesSection
                }
                .padding(.horizontal, LocusDesign.pagePadding)
                .padding(.bottom, 2)
            }
            .scrollIndicators(.automatic)
            footer.padding(.top, 12)
        }
    }

    private var header: some View {
        HStack {
            LocusMark().frame(width: LocusDesign.brandMarkSize, height: LocusDesign.brandMarkSize)
            Spacer()
            HStack(spacing: 8) {
                Text(model.preferences.automationEnabled ? "自动控制" : "已暂停")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Toggle("自动控制", isOn: Binding(
                    get: { model.preferences.automationEnabled },
                    set: model.setAutomationEnabled
                ))
                .labelsHidden()
                .toggleStyle(LocusSwitchStyle())
            }
        }
        .padding(.horizontal, 18)
        .frame(height: LocusDesign.headerHeight)
    }

    private var environmentSection: some View {
        LocusCard {
            HStack(spacing: 11) {
                Image(systemName: model.currentNetwork?.kind == .ethernet ? "cable.connector" : model.currentNetwork == nil ? "network.slash" : "wifi")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(model.currentNetwork == nil ? Color.gray : Color.accentColor, in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 5) {
                    Text(environmentName)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                        .help(environmentName)
                    HStack(spacing: 4) {
                        Image(systemName: runtimeSymbol).foregroundStyle(runtimeColor)
                        Text(runtimeText).foregroundStyle(.secondary)
                    }
                    .font(.system(size: 10))
                    .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if let destination = environmentDestination {
                    Button { router.route = destination } label: {
                        if destination == .addRule || destination == .permission {
                            Text(destination == .addRule ? "添加规则" : "授权")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color.accentColor)
                        } else {
                            Image(systemName: "pencil")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 10)
                    .accessibilityLabel(environmentActionTitle)
                    .help(environmentActionTitle)
                }
            }
            .frame(minHeight: 73)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("当前网络")
    }

    private var audioSection: some View {
        LocusCard {
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Text("声音").font(.system(size: 12, weight: .semibold))
                    Spacer()
                    Text(model.currentMuted ? "已静音" : "\(Int((model.currentVolume * 100).rounded()))%")
                        .font(.system(size: 11))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                Label(model.currentDevice?.name ?? "未找到输出设备", systemImage: "speaker.wave.2")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .help(model.currentDevice?.name ?? "未找到输出设备")
                HStack(spacing: 9) {
                    Button {
                        model.setCurrentMutedInteractively(!model.currentMuted)
                    } label: {
                        Image(systemName: model.currentMuted ? "speaker.slash" : "speaker.fill")
                            .frame(width: 16, height: 18)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(model.currentMuted ? "取消静音" : "静音")
                    .help(model.currentMuted ? "取消静音" : "静音")
                    Slider(value: Binding(get: { model.currentVolume }, set: model.setCurrentVolumeInteractively), in: 0...1)
                        .controlSize(.small)
                        .accessibilityLabel("当前音量")
                    Image(systemName: "speaker.wave.2.fill").accessibilityHidden(true)
                }
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .disabled(model.currentDevice == nil)
                Text("连接此网络时自动恢复声音设置")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 25)
            }
            .padding(.vertical, 12)
        }
    }

    private var rulesSection: some View {
        VStack(spacing: 7) {
            HStack {
                Text("网络规则").foregroundStyle(.secondary)
                Spacer()
                Button { router.route = .addRule } label: {
                    Label("添加", systemImage: "plus")
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("添加网络规则")
            }
            .font(.system(size: 11, weight: .medium))
            .padding(.horizontal, 4)
            .padding(.top, 3)
            LocusCard {
                VStack(spacing: 0) {
                    ForEach(Array(orderedRules.enumerated()), id: \.element.id) { index, rule in
                        if index > 0 { Divider().padding(.leading, 26) }
                        Button { router.route = .rule(rule.id) } label: { ruleRow(rule) }
                            .buttonStyle(LocusRowButtonStyle())
                    }
                    if orderedRules.isEmpty {
                        Button { router.route = .addRule } label: {
                            Label("为当前网络添加规则", systemImage: "plus")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.accentColor)
                                .frame(maxWidth: .infinity, minHeight: 43, alignment: .leading)
                        }
                        .buttonStyle(LocusRowButtonStyle())
                    }
                }
            }
        }
    }

    private func ruleRow(_ rule: WiFiRule) -> some View {
        HStack(spacing: 9) {
            Image(systemName: rule.isFallback ? "globe" : rule.kind == .ethernet ? "cable.connector" : "wifi")
                .font(.system(size: 13))
                .foregroundStyle(model.isCurrentNetwork(rule) ? Color.accentColor : .secondary)
                .frame(width: 17)
            Text(rule.displayName)
                .font(.system(size: 12, weight: model.isCurrentNetwork(rule) ? .medium : .regular))
                .foregroundStyle(rule.isEnabled ? .primary : .secondary)
                .lineLimit(1)
                .help(rule.displayName)
                .layoutPriority(1)
            if model.isCurrentNetwork(rule) {
                Text("当前")
                    .fixedSize()
                    .font(.system(size: 9))
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.07), in: RoundedRectangle(cornerRadius: 4))
            }
            Spacer(minLength: 4)
            Text(ruleSummary(rule))
                .font(.system(size: 11))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .fixedSize()
            Image(systemName: "chevron.right")
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(.tertiary)
        }
        .frame(minHeight: 42.5)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("打开规则详情")
    }

    private var footer: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                Button { router.route = .activity } label: {
                    Label(activitySummary, systemImage: "clock.arrow.circlepath")
                        .font(.system(size: 10))
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("查看最近活动，\(activitySummary)")
                Spacer(minLength: 8)
                Button { router.route = .settings } label: {
                    Image(systemName: "gearshape").font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 28)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("打开设置")
                .help("设置")
            }
            .padding(.horizontal, 18)
            .frame(height: 46)
        }
    }

    private var currentEnvironmentRule: WiFiRule? { model.rules.first { model.isCurrentNetwork($0) } }

    private var environmentName: String {
        currentEnvironmentRule?.displayName ?? model.currentNetwork?.name ?? "未连接网络"
    }

    private var environmentDestination: PanelRoute? {
        if model.needsWiFiPermission { return .permission }
        guard model.currentNetwork?.identifier?.isEmpty == false else { return nil }
        return currentEnvironmentRule.map { .rule($0.id) } ?? .addRule
    }

    private var environmentActionTitle: String {
        if model.needsWiFiPermission { return "授权读取 Wi-Fi 名称" }
        return currentEnvironmentRule == nil ? "为当前网络添加规则" : "编辑当前网络规则"
    }

    private var runtimeText: String {
        switch model.runtimeState {
        case .ready:
            guard let matching = model.matchingRule else { return "此网络尚未设置规则" }
            guard model.lastAppliedRule == matching else { return "已连接 · 规则已保存" }
            return matching.isFallback ? "已连接 · 已应用其他网络规则" : "已连接 · 规则已应用"
        case .applying: return "正在应用声音规则"
        case .noMatchingRule:
            guard let currentEnvironmentRule else { return "此网络尚未设置规则" }
            return currentEnvironmentRule.isEnabled ? "已连接 · 规则已保存" : "当前规则已停用"
        case .waitingForPermission: return "需要权限才能读取 Wi-Fi 名称"
        case .error: return "应用失败 · 请查看规则"
        default: return model.runtimeState.shortLabel
        }
    }

    private var runtimeSymbol: String {
        switch model.runtimeState {
        case .ready: return model.matchingRule == nil ? "plus.circle" : model.lastAppliedRule == model.matchingRule ? "checkmark" : "checkmark.circle"
        case .applying, .starting: return "arrow.triangle.2.circlepath"
        case .paused: return "pause"
        case .noMatchingRule: return "plus.circle"
        case .disconnected: return "network.slash"
        case .waitingForPermission, .error: return "exclamationmark.circle"
        }
    }

    private var runtimeColor: Color {
        switch model.runtimeState {
        case .ready: return model.matchingRule != nil && model.lastAppliedRule == model.matchingRule ? .green : .secondary
        case .applying, .starting: return .accentColor
        case .error: return .red
        case .waitingForPermission: return .orange
        default: return .secondary
        }
    }

    private func ruleSummary(_ rule: WiFiRule) -> String {
        if !rule.isEnabled { return "已停用" }
        return rule.mutePolicy == .mute ? "静音" : "\(Int((rule.targetVolume * 100).rounded()))%"
    }

    private var orderedRules: [WiFiRule] {
        model.rules.sorted {
            let left = model.isCurrentNetwork($0) ? 0 : $0.isFallback ? 2 : 1
            let right = model.isCurrentNetwork($1) ? 0 : $1.isFallback ? 2 : 1
            return left == right ? $0.createdAt < $1.createdAt : left < right
        }
    }

    private var activitySummary: String {
        guard let activity = model.activities.first(where: { $0.kind == .ruleApplied }) else { return "最近活动" }
        return "\(locusRelativeTime(from: activity.date))应用了声音规则"
    }
}
