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
                            VStack(alignment: .leading, spacing: 10) {
                                Picker("连接方式", selection: $networkKind) {
                                    ForEach(NetworkKind.allCases) { kind in
                                        Text(kind.displayName).tag(kind)
                                    }
                                }
                                .pickerStyle(.segmented)
                                HStack(alignment: .top, spacing: 10) {
                                    LocusIconTile(symbol: networkKind.symbol)
                                    VStack(alignment: .leading, spacing: 6) {
                                        if networkKind == .wifi {
                                            Text("Wi‑Fi 名称").font(.system(size: 12.5, weight: .semibold))
                                            TextField("例如 Home Wi‑Fi", text: Binding(
                                                get: { ssid },
                                                set: {
                                                    didEditSSID = true
                                                    ssid = String($0.prefix(32))
                                                }
                                            ))
                                            .textFieldStyle(.roundedBorder)
                                        } else if let wiredNetwork {
                                            Text("规则名称").font(.system(size: 12.5, weight: .semibold))
                                            TextField("例如 办公室有线网络", text: $wiredName)
                                                .textFieldStyle(.roundedBorder)
                                            Text(wiredNetwork.detail)
                                                .font(.system(size: 10.5))
                                                .foregroundStyle(.secondary)
                                            Text("保存后，之后连接此网络时自动匹配。")
                                                .font(.system(size: 10.5))
                                                .foregroundStyle(.secondary)
                                        } else {
                                            Text("请先连接有线网络")
                                                .font(.system(size: 12.5, weight: .semibold))
                                            Text("使用系统当前主网络创建有线规则。")
                                                .font(.system(size: 10.5))
                                                .foregroundStyle(.secondary)
                                        }
                                        if (didEditSSID || networkKind == .ethernet), let validationMessage {
                                            Label(validationMessage, systemImage: "exclamationmark.circle.fill")
                                                .font(.system(size: 10.5))
                                                .foregroundStyle(.red)
                                        }
                                    }
                                }
                            }.padding(.vertical, 11)
                        }
                    }

                    MenuBarSection(title: "声音") {
                        LocusCard { VStack(spacing: 0) {
                            MenuBarRow(title: "输出设备", subtitle: "不选择时保持当前设备", icon: "speaker.wave.2.fill") {
                                Picker("输出设备", selection: $outputDeviceUID) {
                                    Text("保持当前设备").tag(String?.none)
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
                                    Text(volume, format: .percent.precision(.fractionLength(0)))
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }
                                Slider(value: $volume, in: 0...1)
                                }
                            }
                            .padding(.vertical, 8)
                        } }
                    }

                }
                .padding(.horizontal, LocusDesign.pagePadding)
                .padding(.vertical, 6)
            }
            .scrollIndicators(.hidden)

            Divider()
            HStack {
                Text("保存后将在连接此网络时自动应用")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
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
                .buttonStyle(LocusAccentButtonStyle())
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
            } else {
                ssid = ""
            }
            volume = model.currentVolume
            outputDeviceUID = nil
            didEditSSID = false
            model.lastErrorMessage = nil
        }
        .onChange(of: model.currentNetwork) { _, connection in
            updateWiredNetwork(connection)
        }
    }

    private func updateWiredNetwork(_ connection: NetworkConnection?) {
        let oldDefaultName = wiredNetwork.map { "有线网络 · \($0.detail)" }
        let usesDefaultName = wiredName.isEmpty || wiredName == oldDefaultName
        wiredNetwork = connection?.kind == .ethernet ? connection : nil
        if usesDefaultName {
            wiredName = wiredNetwork.map { "有线网络 · \($0.detail)" } ?? ""
        }
    }

    private var validationMessage: String? {
        let identifier: String
        if networkKind == .wifi {
            identifier = RuleMatcher.normalizedSSID(ssid)
            if identifier.isEmpty { return "请输入 Wi‑Fi 名称" }
        } else {
            guard let value = wiredNetwork?.identifier else { return "等待有线网络信息就绪后重新添加" }
            identifier = value
            if wiredName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "请输入规则名称" }
        }
        if model.rules.contains(where: { !$0.isFallback && $0.kind == networkKind && $0.ssid == identifier }) {
            return "该网络已有规则"
        }
        return nil
    }
}
