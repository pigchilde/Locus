import LocusCore
import SwiftUI

struct MenuBarRuleDetailView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var router: PanelRouter
    let ruleID: UUID
    @State private var isConfirmingDelete: Bool
    @State private var draftVolume: Double?
    @State private var draftName = ""

    init(ruleID: UUID, initiallyConfirmingDelete: Bool = false) {
        self.ruleID = ruleID
        _isConfirmingDelete = State(initialValue: initiallyConfirmingDelete)
    }

    var body: some View {
        VStack(spacing: 0) {
            MenuBarHeader(title: "规则详情", onBack: router.showHome)
            if let rule {
                ScrollView {
                    VStack(alignment: .leading, spacing: LocusDesign.sectionSpacing) {
                        statusSection(rule)
                        soundSection(rule)
                        behaviorSection(rule)
                        if let message = model.lastErrorMessage {
                            Label(message, systemImage: "exclamationmark.circle")
                                .font(.system(size: 11))
                                .foregroundStyle(.red)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 4)
                        }
                    }
                    .padding(.horizontal, LocusDesign.pagePadding)
                    .padding(.bottom, 12)
                }
                .scrollIndicators(.automatic)
                actionFooter(rule)
            } else {
                ContentUnavailableView {
                    Label("规则不存在", systemImage: "wifi.exclamationmark")
                } description: {
                    Text("这条规则可能已经被删除。")
                } actions: {
                    Button("返回首页", action: router.showHome)
                }
            }
        }
        .onAppear {
            draftVolume = rule?.targetVolume
            draftName = rule?.displayName ?? ""
            model.lastErrorMessage = nil
        }
        .onChange(of: draftName) { _, value in
            let name = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, var updated = rule, updated.displayName != name else { return }
            updated.displayName = name
            model.updateRule(updated)
        }
        .onExitCommand {
            if isConfirmingDelete { isConfirmingDelete = false }
            else { router.showHome() }
        }
    }

    private var rule: WiFiRule? { model.rule(withID: ruleID) }

    private func statusSection(_ rule: WiFiRule) -> some View {
        MenuBarSection(title: "网络") {
            LocusCard {
                VStack(spacing: 0) {
                    MenuBarRow(
                        title: rule.displayName,
                        subtitle: rule.isFallback ? "未保存网络的默认规则" : model.isCurrentNetwork(rule) ? "当前已连接" : "连接此\(rule.kind.displayName)时自动应用",
                        icon: rule.isFallback ? "globe" : rule.kind == .ethernet ? "cable.connector" : "wifi",
                        iconColor: model.isCurrentNetwork(rule) ? .accentColor : .secondary
                    ) {
                        Toggle("启用规则", isOn: binding(rule, \.isEnabled))
                            .labelsHidden().toggleStyle(LocusSwitchStyle())
                    }
                    if !rule.isFallback {
                        Divider()
                        HStack(spacing: 12) {
                            Text("名称").font(.system(size: 12))
                            TextField(rule.kind == .ethernet ? "例如 办公室有线网络" : "例如 家庭 Wi-Fi", text: $draftName)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 11))
                                .accessibilityLabel("规则名称")
                        }
                        .frame(minHeight: 39)
                        if rule.kind == .wifi {
                            Text("匹配 Wi-Fi：\(rule.ssid)")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.bottom, 10)
                        }
                    }
                }
            }
        }
    }

    private func soundSection(_ rule: WiFiRule) -> some View {
        MenuBarSection(title: "声音") {
            LocusCard {
                VStack(spacing: 0) {
                    MenuBarRow(title: "输出设备", icon: "speaker.wave.2") {
                        Picker("输出设备", selection: outputDeviceBinding(rule)) {
                            Text("保持当前设备").tag(String?.none)
                            if let uid = unavailableSelectedDeviceUID(rule) {
                                Text("\(rule.outputDeviceName ?? "已保存设备")（不可用）").tag(Optional(uid))
                            }
                            ForEach(model.availableDevices) { device in
                                Text(device.name).tag(Optional(device.uid))
                            }
                        }
                        .modifier(LocusMenuPickerStyle())
                        .help(rule.outputDeviceName ?? "保持当前设备")
                    }
                    if unavailableSelectedDeviceUID(rule) != nil {
                        Label("所选设备当前不可用，连接后才可应用。", systemImage: "exclamationmark.circle")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 8)
                    }
                    Divider()
                    LocusVolumeEditor(value: Binding(
                        get: { draftVolume ?? rule.targetVolume },
                        set: { draftVolume = $0 }
                    ), onEditingChanged: { editing in
                        guard !editing, let draftVolume, var updated = model.rule(withID: rule.id) else { return }
                        updated.targetVolume = draftVolume
                        model.updateRule(updated)
                    })
                    Divider()
                    MenuBarRow(title: "静音状态", icon: "speaker.slash") {
                        Picker("静音状态", selection: binding(rule, \.mutePolicy)) {
                            ForEach(MutePolicy.allCases) { Text($0.displayName).tag($0) }
                        }
                        .modifier(LocusMenuPickerStyle())
                    }
                }
            }
        }
    }

    private func behaviorSection(_ rule: WiFiRule) -> some View {
        MenuBarSection(title: "行为") {
            LocusCard {
                VStack(spacing: 0) {
                    MenuBarRow(title: "调整方式", icon: "slider.horizontal.3") {
                        Picker("调整方式", selection: binding(rule, \.transition)) {
                            ForEach(VolumeTransition.allCases) { Text($0.displayName).tag($0) }
                        }
                        .modifier(LocusMenuPickerStyle())
                    }
                    Divider()
                    MenuBarRow(title: "规则通知", icon: "bell") {
                        Toggle("规则通知", isOn: binding(rule, \.showsNotification))
                            .labelsHidden().toggleStyle(LocusSwitchStyle())
                    }
                }
            }
        }
    }

    private func actionFooter(_ rule: WiFiRule) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
            if isConfirmingDelete && !rule.isFallback {
                VStack(alignment: .leading, spacing: 8) {
                    Text("删除“\(rule.displayName)”？")
                        .font(.system(size: 12, weight: .semibold))
                        .fixedSize(horizontal: false, vertical: true)
                    Text("以后连接此网络时，不再自动应用这条规则。")
                        .font(.system(size: 10))
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
                .padding(14)
            } else {
                HStack {
                    if !rule.isFallback {
                        Button(role: .destructive) { isConfirmingDelete = true } label: {
                            Label("删除规则", systemImage: "trash")
                        }
                        .buttonStyle(LocusDangerButtonStyle())
                    } else {
                        Text("设置自动保存").font(.system(size: 10)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        model.lastErrorMessage = nil
                        model.applyRuleNow(model.rule(withID: rule.id) ?? rule)
                    } label: {
                        Label(isApplying(rule) ? "正在应用" : "立即应用", systemImage: isApplying(rule) ? "arrow.triangle.2.circlepath" : "play.fill")
                    }
                    .buttonStyle(LocusPrimaryButtonStyle())
                    .disabled(!rule.isEnabled || isApplying(rule))
                }
                .padding(.horizontal, LocusDesign.pagePadding)
                .frame(height: LocusDesign.bottomBarHeight)
            }
        }
    }

    private func binding<Value>(_ rule: WiFiRule, _ keyPath: WritableKeyPath<WiFiRule, Value>) -> Binding<Value> {
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
        Binding(get: { model.rule(withID: rule.id)?.outputDeviceUID }, set: { uid in
            guard var updated = model.rule(withID: rule.id) else { return }
            if let uid, let device = model.availableDevices.first(where: { $0.uid == uid }) {
                updated.outputDeviceUID = device.uid
                updated.outputDeviceName = device.name
            } else if uid == nil {
                updated.outputDeviceUID = nil
                updated.outputDeviceName = nil
            }
            model.updateRule(updated)
        })
    }

    private func unavailableSelectedDeviceUID(_ rule: WiFiRule) -> String? {
        guard let uid = rule.outputDeviceUID else { return nil }
        return model.availableDevices.contains(where: { $0.uid == uid }) ? nil : uid
    }

    private func isApplying(_ rule: WiFiRule) -> Bool {
        guard case .applying(let name) = model.runtimeState else { return false }
        return name == rule.displayName
    }
}
