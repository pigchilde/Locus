import AppKit
import LocusCore
import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var permissions: PermissionService

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SettingsSection(title: "显示") {
                    SettingRow(
                        title: "配色方案",
                        hint: "选择浅色、深色，或跟随系统设置"
                    ) {
                        Picker("", selection: Binding(
                            get: { model.preferences.appearance },
                            set: model.setAppearance
                        )) {
                            ForEach(AppearanceMode.allCases) { appearance in
                                Text(appearance.displayName).tag(appearance)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                        .frame(width: 230)
                    }
                }

                SettingsSection(title: "通用") {
                    SettingRow(
                        title: "自动控制音量",
                        hint: "监听 Wi‑Fi 变化并应用规则"
                    ) {
                        Toggle("", isOn: Binding(
                            get: { model.preferences.automationEnabled },
                            set: model.setAutomationEnabled
                        ))
                        .labelsHidden()
                        .toggleStyle(.switch)
                    }
                    Divider()
                    SettingRow(
                        title: "登录时打开",
                        hint: "让 Locus 在登录后自动待命"
                    ) {
                        Toggle("", isOn: Binding(
                            get: { model.preferences.launchAtLogin },
                            set: model.setLaunchAtLogin
                        ))
                        .labelsHidden()
                        .toggleStyle(.switch)
                    }
                }

                SettingsSection(title: "切换") {
                    SettingRow(
                        title: "切换延迟",
                        hint: "等待网络稳定后再应用规则"
                    ) {
                        Picker("", selection: Binding(
                            get: { model.preferences.switchDelay },
                            set: model.setSwitchDelay
                        )) {
                            Text("立即").tag(TimeInterval(0))
                            Text("1 秒").tag(TimeInterval(1))
                            Text("3 秒").tag(TimeInterval(3))
                            Text("5 秒").tag(TimeInterval(5))
                        }
                        .labelsHidden()
                        .frame(width: 130)
                    }
                    Divider()
                    SettingRow(
                        title: "没有匹配规则时",
                        hint: "控制未保存网络的音量行为"
                    ) {
                        Picker("", selection: Binding(
                            get: { model.preferences.useFallbackRule },
                            set: model.setUseFallback
                        )) {
                            Text("应用“其他网络”").tag(true)
                            Text("保持不变").tag(false)
                        }
                        .labelsHidden()
                        .frame(width: 160)
                    }
                }

                SettingsSection(title: "权限") {
                    SettingRow(
                        title: "位置服务",
                        hint: "仅用于读取当前 Wi‑Fi 名称"
                    ) {
                        HStack(spacing: 8) {
                            permissionStatus
                            Button(permissions.isDenied ? "打开系统设置" : "允许") {
                                if permissions.isDenied {
                                    openLocationSettings()
                                } else {
                                    model.requestLocationPermission()
                                }
                            }
                            .disabled(permissions.canReadWiFiName)
                        }
                    }
                    Divider()
                    SettingRow(
                        title: "系统通知",
                        hint: "规则生效后显示低打扰通知"
                    ) {
                        Button("请求通知权限") {
                            Task { _ = await model.requestNotificationPermission() }
                        }
                    }
                }

                SettingsSection(title: "隐私") {
                    SettingRow(
                        title: "所有规则仅保存在此 Mac",
                        hint: "Locus 不上传网络名称、位置或使用记录"
                    ) {
                        Image(systemName: "lock.shield")
                            .foregroundStyle(.secondary)
                    }
                }

                Text("Locus 1.0.0")
                    .font(.system(size: 10.5))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 5)
            }
            .frame(maxWidth: 620, alignment: .leading)
            .padding(.horizontal, 40)
            .padding(.vertical, 30)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var permissionStatus: some View {
        Label(
            permissions.canReadWiFiName ? "已允许" : "未允许",
            systemImage: permissions.canReadWiFiName ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
        )
        .font(.system(size: 10.5))
        .foregroundStyle(permissions.canReadWiFiName ? Color.green : Color.orange)
    }

    private func openLocationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") {
            NSWorkspace.shared.open(url)
        }
    }
}
