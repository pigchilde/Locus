import LocusCore
import SwiftUI

struct MenuBarRuleDetailView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var router: PanelRouter

    let ruleID: UUID
    @State private var isConfirmingDelete: Bool
    @State private var draftVolume: Double?

    init(ruleID: UUID, initiallyConfirmingDelete: Bool = false) {
        self.ruleID = ruleID
        _isConfirmingDelete = State(initialValue: initiallyConfirmingDelete)
        _draftVolume = State(initialValue: nil)
    }

    var body: some View {
        VStack(spacing: 0) {
            MenuBarHeader(title: rule?.displayName ?? "规则", onBack: router.showHome)

            if let rule {
                ScrollView {
                    VStack(alignment: .leading, spacing: LocusDesign.sectionSpacing) {
                        statusSection(rule)
                        soundSection(rule)
                        behaviorSection(rule)
                        actionSection(rule)
                    }
                    .padding(.horizontal, LocusDesign.pagePadding)
                    .padding(.vertical, 6)
                }
                .scrollIndicators(.hidden)
            } else {
                ContentUnavailableView {
                    Label("规则不存在", systemImage: "wifi.exclamationmark")
                } description: {
                    Text("这条规则可能已经被删除。")
                } actions: {
                    Button("返回首页", action: router.showHome)
                        .buttonStyle(LocusPrimaryButtonStyle())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            draftVolume = rule?.targetVolume
            model.lastErrorMessage = nil
        }
        .onExitCommand {
            if isConfirmingDelete {
                isConfirmingDelete = false
            } else {
                router.showHome()
            }
        }
    }

    private var rule: WiFiRule? {
        model.rule(withID: ruleID)
    }

    private func statusSection(_ rule: WiFiRule) -> some View {
        MenuBarSection(title: "规则") {
            LocusCard { MenuBarRow(
                title: rule.isFallback ? "其他网络" : rule.ssid,
                subtitle: rule.isFallback ? "未保存网络的默认规则" : currentRuleDescription(rule)
            ) {
                Toggle("启用规则", isOn: binding(rule, \.isEnabled))
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
            } }
        }
    }

    private func soundSection(_ rule: WiFiRule) -> some View {
        MenuBarSection(title: "声音") {
            LocusCard { VStack(spacing: 0) {
                MenuBarRow(title: "输出设备", subtitle: selectedDeviceDescription(rule), icon: "speaker.wave.2.fill") {
                    Picker("输出设备", selection: outputDeviceBinding(rule)) {
                        Text("保持当前设备").tag(String?.none)
                        if let uid = unavailableSelectedDeviceUID(rule) {
                            Text("\(rule.outputDeviceName ?? "已保存设备")（当前不可用）")
                                .tag(Optional(uid))
                        }
                        ForEach(model.availableDevices) { device in
                            Text(device.name).tag(Optional(device.uid))
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .tint(.primary)
                    .frame(maxWidth: 155)
                }

                Divider()

                HStack(alignment: .top, spacing: 10) {
                    LocusIconTile(symbol: "chart.bar.fill")
                    VStack(alignment: .leading, spacing: 7) {
                    HStack {
                        Text("目标音量")
                            .font(.system(size: 12.5, weight: .medium))
                        Spacer()
                        Text(draftVolume ?? rule.targetVolume, format: .percent.precision(.fractionLength(0)))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 9) {
                        Image(systemName: "speaker.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                        Slider(
                            value: Binding(
                                get: { draftVolume ?? rule.targetVolume },
                                set: { draftVolume = $0 }
                            ),
                            in: 0...1,
                            onEditingChanged: { isEditing in
                                guard !isEditing, let draftVolume,
                                      var updated = model.rule(withID: rule.id) else { return }
                                updated.targetVolume = draftVolume
                                model.updateRule(updated)
                            }
                        )
                        .accessibilityLabel("目标音量")
                        .accessibilityValue(Text(draftVolume ?? rule.targetVolume, format: .percent))
                    }
                }
                }
                .padding(.vertical, 8)

                Divider()

                MenuBarRow(title: "静音状态", icon: "speaker.slash.fill") {
                    Picker("静音状态", selection: binding(rule, \.mutePolicy)) {
                        ForEach(MutePolicy.allCases) { policy in
                            Text(policy.displayName).tag(policy)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .tint(.primary)
                    .frame(maxWidth: 155)
                }
            } }
        }
    }

    private func behaviorSection(_ rule: WiFiRule) -> some View {
        MenuBarSection(title: "行为") {
            LocusCard { VStack(spacing: 0) {
                MenuBarRow(title: "调整方式", icon: "slider.horizontal.3") {
                    Picker("调整方式", selection: binding(rule, \.transition)) {
                        ForEach(VolumeTransition.allCases) { transition in
                            Text(transition.displayName).tag(transition)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .tint(.primary)
                    .frame(maxWidth: 155)
                }
                Divider()
                MenuBarRow(title: "规则通知", subtitle: "规则应用成功后通知", icon: "bell") {
                    Toggle("规则通知", isOn: binding(rule, \.showsNotification))
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }
            } }
        }
    }

    @ViewBuilder
    private func actionSection(_ rule: WiFiRule) -> some View {
        MenuBarSection(title: "操作") {
            if let message = model.lastErrorMessage {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(message)
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(10)
                .background(Color.red.opacity(0.06), in: RoundedRectangle(cornerRadius: 9))
            }

            if !rule.isFallback, isConfirmingDelete {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text("删除“\(rule.displayName)”？")
                            .font(.system(size: 12.5, weight: .semibold))
                    }
                    Text("以后连接此 Wi‑Fi 时将不再自动调整声音。")
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)
                    HStack {
                        Spacer()
                        Button("取消") { isConfirmingDelete = false }
                            .buttonStyle(LocusSecondaryButtonStyle())
                        Button("确认删除", role: .destructive) {
                            model.deleteRule(id: rule.id)
                            router.showHome()
                        }
                        .buttonStyle(LocusDangerButtonStyle())
                    }
                }
                .padding(11)
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 9))
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(Color.red.opacity(0.16), lineWidth: 0.5)
                )
            }

            HStack(spacing: 8) {
                if !rule.isFallback, !isConfirmingDelete {
                    Button(role: .destructive) {
                        isConfirmingDelete = true
                    } label: {
                        Label("删除规则", systemImage: "trash")
                    }
                    .buttonStyle(LocusDangerButtonStyle())
                }

                Spacer()

                if isConfirmingDelete {
                    applyButton(rule)
                        .buttonStyle(LocusSecondaryButtonStyle())
                } else {
                    applyButton(rule)
                        .buttonStyle(LocusPrimaryButtonStyle())
                }
            }
        }
    }

    private func binding<Value>(
        _ rule: WiFiRule,
        _ keyPath: WritableKeyPath<WiFiRule, Value>
    ) -> Binding<Value> {
        Binding(
            get: { model.rule(withID: rule.id)?[keyPath: keyPath] ?? rule[keyPath: keyPath] },
            set: { value in
                guard var updated = model.rule(withID: rule.id) else { return }
                updated[keyPath: keyPath] = value
                model.updateRule(updated)
            }
        )
    }

    private func outputDeviceBinding(_ rule: WiFiRule) -> Binding<String?> {
        Binding(
            get: { model.rule(withID: rule.id)?.outputDeviceUID },
            set: { uid in
                guard var updated = model.rule(withID: rule.id) else { return }
                if let uid, let device = model.availableDevices.first(where: { $0.uid == uid }) {
                    updated.outputDeviceUID = device.uid
                    updated.outputDeviceName = device.name
                } else if uid == nil {
                    updated.outputDeviceUID = nil
                    updated.outputDeviceName = nil
                }
                model.updateRule(updated)
            }
        )
    }

    private func unavailableSelectedDeviceUID(_ rule: WiFiRule) -> String? {
        guard let uid = rule.outputDeviceUID else { return nil }
        return model.availableDevices.contains(where: { $0.uid == uid }) ? nil : uid
    }

    private func selectedDeviceDescription(_ rule: WiFiRule) -> String {
        guard let uid = rule.outputDeviceUID else { return "保持当前设备" }
        if model.availableDevices.contains(where: { $0.uid == uid }) {
            return rule.outputDeviceName ?? "已选择设备"
        }
        return "\(rule.outputDeviceName ?? "已保存设备")（当前不可用）"
    }

    private func currentRuleDescription(_ rule: WiFiRule) -> String {
        if model.currentSSID == rule.ssid {
            return model.matchingRule?.id == rule.id ? "当前已连接并匹配" : "当前已连接"
        }
        return "连接此 Wi‑Fi 时自动应用"
    }

    private func isApplying(_ rule: WiFiRule) -> Bool {
        guard case .applying(let name) = model.runtimeState else { return false }
        return name == rule.displayName
    }

    private func applyButton(_ rule: WiFiRule) -> some View {
        Button {
            model.lastErrorMessage = nil
            model.applyRuleNow(rule)
        } label: {
            if isApplying(rule) {
                HStack(spacing: 6) {
                    ProgressView().controlSize(.small)
                    Text("正在应用")
                }
            } else {
                Label("立即应用", systemImage: "play.fill")
            }
        }
        .disabled(!rule.isEnabled || isApplying(rule))
    }
}
