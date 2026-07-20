import LocusCore
import SwiftUI

struct RuleDetailView: View {
    @EnvironmentObject private var model: AppModel
    let ruleID: UUID

    @State private var isConfirmingDelete = false

    var body: some View {
        if let rule = model.rule(withID: ruleID) {
            ScrollView {
                VStack(alignment: .leading, spacing: 19) {
                    header(rule)
                    ruleGroup(rule)
                    soundGroup(rule)
                    behaviorGroup(rule)
                    footer(rule)
                }
                .frame(maxWidth: 620, alignment: .leading)
                .padding(.horizontal, 34)
                .padding(.vertical, 26)
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .confirmationDialog(
                "删除“\(rule.displayName)”规则？",
                isPresented: $isConfirmingDelete
            ) {
                Button("删除", role: .destructive) {
                    model.deleteRule(id: rule.id)
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("以后连接此 Wi‑Fi 时将不再自动调整音量。")
            }
        }
    }

    private func header(_ rule: WiFiRule) -> some View {
        HStack(spacing: 13) {
            Image(systemName: "wifi")
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(Color.accentColor)
                .frame(width: 42, height: 42)
                .background(Color.accentColor.opacity(0.09), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 3) {
                Text(rule.displayName)
                    .font(.system(size: 19, weight: .bold))
                Text(headerSubtitle(rule))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("立即应用") {
                model.applyRuleNow(rule)
            }
            .disabled(!rule.isEnabled)
        }
    }

    private func headerSubtitle(_ rule: WiFiRule) -> String {
        if rule.isFallback { return "未保存网络的默认规则" }
        if model.currentSSID == rule.ssid {
            return model.matchingRule?.id == rule.id ? "当前已连接 · 规则已生效" : "当前已连接"
        }
        return "连接此 Wi‑Fi 时自动应用"
    }

    private func ruleGroup(_ rule: WiFiRule) -> some View {
        SettingsSection(title: "规则") {
            SettingRow(
                title: "启用此规则",
                hint: "连接此 Wi‑Fi 时自动应用"
            ) {
                Toggle("", isOn: binding(rule, \.isEnabled))
                    .labelsHidden()
                    .toggleStyle(.switch)
            }
            Divider()
            SettingRow(
                title: "输出设备",
                hint: "目标设备不可用时仍会调整当前设备音量"
            ) {
                Picker("", selection: outputDeviceBinding(rule)) {
                    Text("保持当前设备").tag(String?.none)
                    ForEach(model.availableDevices) { device in
                        Text(device.name).tag(Optional(device.uid))
                    }
                }
                .labelsHidden()
                .frame(width: 190)
            }
        }
    }

    private func soundGroup(_ rule: WiFiRule) -> some View {
        SettingsSection(title: "声音") {
            SettingRow(
                title: "系统音量",
                hint: "连接后平滑调整，避免突变"
            ) {
                HStack(spacing: 8) {
                    Image(systemName: "speaker.wave.1")
                        .foregroundStyle(.secondary)
                    Slider(value: binding(rule, \.targetVolume), in: 0...1)
                        .frame(width: 170)
                    Text(rule.targetVolume, format: .percent.precision(.fractionLength(0)))
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(width: 36, alignment: .trailing)
                }
            }
            Divider()
            SettingRow(
                title: "静音状态",
                hint: "保持不变或强制设置静音状态"
            ) {
                Picker("", selection: binding(rule, \.mutePolicy)) {
                    ForEach(MutePolicy.allCases) { policy in
                        Text(policy.displayName).tag(policy)
                    }
                }
                .labelsHidden()
                .frame(width: 170)
            }
        }
    }

    private func behaviorGroup(_ rule: WiFiRule) -> some View {
        SettingsSection(title: "行为") {
            SettingRow(
                title: "调整方式",
                hint: "渐变调整更自然"
            ) {
                Picker("", selection: binding(rule, \.transition)) {
                    ForEach(VolumeTransition.allCases) { transition in
                        Text(transition.displayName).tag(transition)
                    }
                }
                .labelsHidden()
                .frame(width: 170)
            }
            Divider()
            SettingRow(
                title: "显示通知",
                hint: "规则生效时显示系统通知"
            ) {
                Toggle("", isOn: binding(rule, \.showsNotification))
                    .labelsHidden()
                    .toggleStyle(.switch)
            }
        }
    }

    @ViewBuilder
    private func footer(_ rule: WiFiRule) -> some View {
        if !rule.isFallback {
            Button(role: .destructive) {
                isConfirmingDelete = true
            } label: {
                Label("删除此规则…", systemImage: "trash")
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .controlSize(.regular)
        }
    }

    private func binding<Value>(
        _ rule: WiFiRule,
        _ keyPath: WritableKeyPath<WiFiRule, Value>
    ) -> Binding<Value> {
        Binding(
            get: { model.rule(withID: rule.id)?[keyPath: keyPath] ?? rule[keyPath: keyPath] },
            set: { newValue in
                guard var updated = model.rule(withID: rule.id) else { return }
                updated[keyPath: keyPath] = newValue
                model.updateRule(updated)
            }
        )
    }

    private func outputDeviceBinding(_ rule: WiFiRule) -> Binding<String?> {
        Binding(
            get: { model.rule(withID: rule.id)?.outputDeviceUID },
            set: { uid in
                guard var updated = model.rule(withID: rule.id) else { return }
                let device = model.availableDevices.first(where: { $0.uid == uid })
                updated.outputDeviceUID = device?.uid
                updated.outputDeviceName = device?.name
                model.updateRule(updated)
            }
        )
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.leading, 2)
            VStack(spacing: 0) {
                content
            }
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.65), lineWidth: 0.5)
            )
        }
    }
}

struct SettingRow<Control: View>: View {
    let title: String
    let hint: String
    @ViewBuilder let control: Control

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 14) {
                rowLabel
                    .frame(minWidth: 170, alignment: .leading)
                Spacer(minLength: 12)
                control
            }

            VStack(alignment: .leading, spacing: 8) {
                rowLabel
                HStack {
                    Spacer(minLength: 0)
                    control
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(minHeight: 46)
    }

    private var rowLabel: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
            Text(hint)
                .font(.system(size: 10.5))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
