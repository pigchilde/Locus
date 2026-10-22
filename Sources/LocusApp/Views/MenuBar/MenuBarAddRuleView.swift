import LocusCore
import SwiftUI

struct MenuBarAddRuleView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var router: PanelRouter
    @State private var ssid = ""
    @State private var networkKind: NetworkKind = .wifi
    @State private var wiredNetwork: NetworkConnection?
    @State private var wiredName = ""
    @State private var volume = 0.35
    @State private var outputDeviceUID: String?
    @State private var didEditSSID = false

    var body: some View {
        VStack(spacing: 0) {
            MenuBarHeader(title: "添加规则", onBack: router.showHome)
            ScrollView {
                VStack(alignment: .leading, spacing: LocusDesign.sectionSpacing) {
                    MenuBarSection(title: "网络") {
                        LocusCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Picker("连接方式", selection: $networkKind) {
                                    ForEach(NetworkKind.allCases) { Text($0.displayName).tag($0) }
                                }
                                .pickerStyle(.segmented)
                                .controlSize(.small)
                                if networkKind == .wifi {
                                    VStack(alignment: .leading, spacing: 7) {
                                        Text("Wi-Fi 名称").font(.system(size: 12, weight: .medium))
                                        TextField("例如 Home Wi-Fi", text: Binding(get: { ssid }, set: {
                                            didEditSSID = true
                                            ssid = String($0.prefix(32))
                                        }))
                                        .textFieldStyle(.roundedBorder)
                                        .font(.system(size: 12))
                                        .accessibilityLabel("Wi-Fi 名称")
                                    }
                                } else if let wiredNetwork {
                                    VStack(alignment: .leading, spacing: 7) {
                                        Text("规则名称").font(.system(size: 12, weight: .medium))
                                        TextField("例如 办公室有线网络", text: $wiredName)
                                            .textFieldStyle(.roundedBorder)
                                            .font(.system(size: 12))
                                            .accessibilityLabel("规则名称")
                                        Text(wiredNetwork.detail)
                                            .font(.system(size: 10))
                                            .foregroundStyle(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                } else {
                                    Label("请先连接有线网络", systemImage: "cable.connector")
                                        .font(.system(size: 12, weight: .medium))
                                    Text("连接后，选择系统当前的主网络创建规则。")
                                        .font(.system(size: 11)).foregroundStyle(.secondary)
                                }
                                if (didEditSSID || networkKind == .ethernet), let validationMessage {
                                    Label(validationMessage, systemImage: "exclamationmark.circle")
                                        .font(.system(size: 10)).foregroundStyle(.red)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(.vertical, 12)
                        }
                    }
                    MenuBarSection(title: "声音") {
                        LocusCard {
                            VStack(spacing: 0) {
                                MenuBarRow(title: "输出设备", icon: "speaker.wave.2") {
                                    Picker("输出设备", selection: $outputDeviceUID) {
                                        Text("保持当前设备").tag(String?.none)
                                        ForEach(model.availableDevices) { Text($0.name).tag(Optional($0.uid)) }
                                    }
                                    .modifier(LocusMenuPickerStyle())
                                }
                                Divider()
                                LocusVolumeEditor(value: $volume)
                            }
                        }
                    }
                    Text("保存后，连接此网络时会自动恢复声音设置。更多选项可在规则详情中调整。")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)
                        .padding(.horizontal, 4)
                    if let message = model.lastErrorMessage {
                        Label(message, systemImage: "exclamationmark.circle")
                            .font(.system(size: 11)).foregroundStyle(.red)
                    }
                }
                .padding(.horizontal, LocusDesign.pagePadding)
                .padding(.bottom, 14)
            }
            Divider()
            HStack {
                Text("保存到此 Mac").font(.system(size: 10)).foregroundStyle(.secondary)
                Spacer()
                Button {
                    guard model.addRule(
                        ssid: networkKind == .wifi ? ssid : wiredNetwork?.identifier ?? "",
                        networkKind: networkKind,
                        displayName: networkKind == .ethernet ? wiredName.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
                        volume: volume,
                        outputDeviceUID: outputDeviceUID
                    ) != nil else { return }
                    router.showHome()
                } label: {
                    Label("添加规则", systemImage: "plus")
                }
                .buttonStyle(LocusPrimaryButtonStyle())
                .keyboardShortcut(.defaultAction)
                .disabled(validationMessage != nil)
            }
            .padding(.horizontal, LocusDesign.pagePadding)
            .frame(height: LocusDesign.bottomBarHeight)
        }
        .onAppear {
            let current = model.currentNetwork
            networkKind = current?.kind ?? .wifi
            updateWiredNetwork(current)
            if current?.kind == .wifi, let identifier = current?.identifier,
               !model.rules.contains(where: { !$0.isFallback && $0.kind == .wifi && $0.ssid == identifier }) {
                ssid = identifier
            } else { ssid = "" }
            volume = model.currentVolume
            outputDeviceUID = nil
            didEditSSID = false
            model.lastErrorMessage = nil
        }
        .onChange(of: model.currentNetwork) { _, connection in updateWiredNetwork(connection) }
    }

    private func updateWiredNetwork(_ connection: NetworkConnection?) {
        let oldDefault = wiredNetwork.map { "\($0.kind.displayName)" }
        let usesDefault = wiredName.isEmpty || wiredName == oldDefault
        wiredNetwork = connection?.kind == .ethernet ? connection : nil
        if usesDefault { wiredName = wiredNetwork == nil ? "" : "有线网络" }
    }

    private var validationMessage: String? {
        let identifier: String
        if networkKind == .wifi {
            identifier = RuleMatcher.normalizedSSID(ssid)
            if identifier.isEmpty { return "请输入 Wi-Fi 名称" }
        } else {
            guard let value = wiredNetwork?.identifier else { return "等待有线网络信息就绪后重新添加" }
            identifier = value
            if wiredName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "请输入规则名称" }
        }
        if model.rules.contains(where: { !$0.isFallback && $0.kind == networkKind && $0.ssid == identifier }) {
            return "该网络已有规则，可返回首页进行编辑。"
        }
        return nil
    }
}
