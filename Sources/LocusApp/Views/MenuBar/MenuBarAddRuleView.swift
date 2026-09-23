import LocusCore
import SwiftUI

struct MenuBarAddRuleView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var router: PanelRouter

    @State private var ssid = ""
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
                            HStack(alignment: .top, spacing: 10) {
                                LocusIconTile(symbol: "wifi")
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Wi‑Fi 名称").font(.system(size: 12.5, weight: .semibold))
                                    TextField("例如 Home Wi‑Fi", text: Binding(
                                get: { ssid },
                                set: {
                                    didEditSSID = true
                                    ssid = String($0.prefix(32))
                                }
                                    ))
                                .textFieldStyle(.roundedBorder)
                                    if didEditSSID, let validationMessage {
                                Label(validationMessage, systemImage: "exclamationmark.circle.fill")
                                    .font(.system(size: 10.5))
                                    .foregroundStyle(.red)
                                    .accessibilityLabel(validationMessage)
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
                        ssid: ssid,
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
            if let currentSSID = model.currentSSID,
               !model.rules.contains(where: { !$0.isFallback && $0.ssid == currentSSID }) {
                ssid = currentSSID
            } else {
                ssid = ""
            }
            volume = model.currentVolume
            outputDeviceUID = nil
            didEditSSID = false
            model.lastErrorMessage = nil
        }
    }

    private var validationMessage: String? {
        let normalized = RuleMatcher.normalizedSSID(ssid)
        if normalized.isEmpty { return "请输入 Wi‑Fi 名称" }
        if model.rules.contains(where: { !$0.isFallback && $0.ssid == normalized }) {
            return "该 Wi‑Fi 已有规则"
        }
        return nil
    }
}
