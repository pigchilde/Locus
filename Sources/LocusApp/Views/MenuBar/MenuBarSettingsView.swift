import AppKit
import LocusCore
import SwiftUI
import UserNotifications

struct MenuBarSettingsView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var permissions: PermissionService
    @EnvironmentObject private var router: PanelRouter
    let onQuit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            MenuBarHeader(title: "设置", onBack: router.showHome)
            ScrollView {
                VStack(alignment: .leading, spacing: LocusDesign.sectionSpacing) {
                    generalSection
                    switchingSection
                    appearanceSection
                    permissionSection
                    aboutSection
                }
                .padding(.horizontal, LocusDesign.pagePadding)
                .padding(.bottom, 14)
            }
            .scrollIndicators(.automatic)
        }
        .onAppear { Task { await model.refreshNotificationAuthorizationStatus() } }
    }

    private var generalSection: some View {
        MenuBarSection(title: "通用") {
            LocusCard {
                VStack(spacing: 0) {
                    MenuBarRow(title: "自动控制", icon: "waveform.path") {
                        Toggle("自动控制", isOn: Binding(get: { model.preferences.automationEnabled }, set: model.setAutomationEnabled))
                            .labelsHidden().toggleStyle(LocusSwitchStyle())
                    }
                    Divider()
                    MenuBarRow(title: "登录时打开", icon: "power") {
                        Toggle("登录时打开", isOn: Binding(get: { model.preferences.launchAtLogin }, set: model.setLaunchAtLogin))
                            .labelsHidden().toggleStyle(LocusSwitchStyle())
                    }
                }
            }
        }
    }

    private var switchingSection: some View {
        MenuBarSection(title: "网络切换") {
            LocusCard {
                VStack(spacing: 0) {
                    MenuBarRow(title: "切换延迟", icon: "clock") {
                        Picker("切换延迟", selection: Binding(get: { model.preferences.switchDelay }, set: model.setSwitchDelay)) {
                            Text("立即").tag(TimeInterval(0))
                            Text("1 秒").tag(TimeInterval(1))
                            Text("3 秒").tag(TimeInterval(3))
                            Text("5 秒").tag(TimeInterval(5))
                        }
                        .modifier(LocusMenuPickerStyle())
                        .help("等待网络稳定后再应用规则")
                    }
                    Divider()
                    MenuBarRow(title: "未保存的网络", icon: "globe") {
                        Picker("未保存的网络", selection: Binding(get: { model.preferences.useFallbackRule }, set: model.setUseFallback)) {
                            Text("应用其他网络规则").tag(true)
                            Text("保持不变").tag(false)
                        }
                        .modifier(LocusMenuPickerStyle())
                    }
                }
            }
        }
    }

    private var appearanceSection: some View {
        MenuBarSection(title: "外观") {
            LocusCard {
                MenuBarRow(title: "配色方案", icon: "circle.lefthalf.filled") {
                    Picker("配色方案", selection: Binding(get: { model.preferences.appearance }, set: model.setAppearance)) {
                        ForEach(AppearanceMode.allCases) { Text($0.displayName).tag($0) }
                    }
                    .modifier(LocusMenuPickerStyle())
                }
            }
        }
    }

    private var permissionSection: some View {
        MenuBarSection(title: "权限") {
            LocusCard {
                VStack(spacing: 0) {
                    MenuBarRow(title: "Wi-Fi 名称", icon: "location") {
                        if model.canReadWiFiName {
                            permissionGranted
                        } else {
                            Button("设置权限") { router.route = .permission }
                                .buttonStyle(LocusSecondaryButtonStyle())
                        }
                    }
                    Divider()
                    MenuBarRow(title: "系统通知", icon: "bell") {
                        switch model.notificationAuthorizationStatus {
                        case .authorized, .provisional, .ephemeral:
                            permissionGranted
                        case .denied:
                            Button("打开设置", action: openNotificationSettings)
                                .buttonStyle(LocusSecondaryButtonStyle())
                        default:
                            Button("允许通知") { Task { _ = await model.requestNotificationPermission() } }
                                .buttonStyle(LocusSecondaryButtonStyle())
                        }
                    }
                }
            }
        }
    }

    private var permissionGranted: some View {
        Label("已允许", systemImage: "checkmark")
            .font(.system(size: 10)).foregroundStyle(.green)
    }

    private var aboutSection: some View {
        MenuBarSection(title: "关于") {
            LocusCard {
                VStack(spacing: 0) {
                    Button { router.route = .activity } label: {
                        MenuBarRow(title: "最近活动", icon: "clock.arrow.circlepath") {
                            Image(systemName: "chevron.right").font(.system(size: 9)).foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(LocusRowButtonStyle())
                    Divider()
                    MenuBarRow(title: "版本", icon: "info.circle") {
                        Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "开发版本")
                            .font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                    Divider()
                    Button(action: onQuit) {
                        MenuBarRow(title: "退出 Locus", icon: "power") { EmptyView() }
                    }
                    .buttonStyle(LocusRowButtonStyle())
                }
            }
            Text("网络、规则和活动记录仅保存在此 Mac。")
                .font(.system(size: 10)).foregroundStyle(.secondary)
                .padding(.horizontal, 4)
        }
    }

    private func openNotificationSettings() {
        guard !model.isPreview else { return }
        let bundleID = Bundle.main.bundleIdentifier ?? "com.locusapp.Locus"
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications?id=\(bundleID)") else { return }
        NSWorkspace.shared.open(url)
    }
}
