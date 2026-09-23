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
                .padding(.vertical, 6)
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            Task { await model.refreshNotificationAuthorizationStatus() }
        }
    }

    private var generalSection: some View {
        MenuBarSection(title: "通用") {
            LocusCard { VStack(spacing: 0) {
                MenuBarRow(title: "自动控制", subtitle: "监听 Wi‑Fi 变化并应用规则", icon: "waveform.path.ecg", iconColor: .accentColor) {
                    Toggle("自动控制", isOn: Binding(
                        get: { model.preferences.automationEnabled },
                        set: model.setAutomationEnabled
                    ))
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
                }
                Divider()
                MenuBarRow(title: "登录时打开", subtitle: "登录后在菜单栏待命", icon: "power") {
                    Toggle("登录时打开", isOn: Binding(
                        get: { model.preferences.launchAtLogin },
                        set: model.setLaunchAtLogin
                    ))
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
                }
            } }
        }
    }

    private var switchingSection: some View {
        MenuBarSection(title: "切换") {
            LocusCard { VStack(spacing: 0) {
                MenuBarRow(title: "切换延迟", subtitle: "等待网络稳定后应用规则", icon: "clock") {
                    Picker("切换延迟", selection: Binding(
                        get: { model.preferences.switchDelay },
                        set: model.setSwitchDelay
                    )) {
                        Text("立即").tag(TimeInterval(0))
                        Text("1 秒").tag(TimeInterval(1))
                        Text("3 秒").tag(TimeInterval(3))
                        Text("5 秒").tag(TimeInterval(5))
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .tint(.primary)
                    .frame(maxWidth: 120)
                }
                Divider()
                MenuBarRow(title: "未保存的网络", subtitle: "没有精确匹配规则时", icon: "arrow.left.arrow.right") {
                    Picker("未保存的网络", selection: Binding(
                        get: { model.preferences.useFallbackRule },
                        set: model.setUseFallback
                    )) {
                        Text("应用其他网络规则").tag(true)
                        Text("保持不变").tag(false)
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .tint(.primary)
                    .frame(maxWidth: 145)
                }
            } }
        }
    }

    private var appearanceSection: some View {
        MenuBarSection(title: "显示") {
            LocusCard { MenuBarRow(title: "配色方案", icon: "paintpalette") {
                Picker("配色方案", selection: Binding(
                    get: { model.preferences.appearance },
                    set: model.setAppearance
                )) {
                    ForEach(AppearanceMode.allCases) { appearance in
                        Text(appearance.displayName).tag(appearance)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .tint(.primary)
                .frame(maxWidth: 130)
            } }
        }
    }

    private var permissionSection: some View {
        MenuBarSection(title: "权限") {
            LocusCard { VStack(spacing: 0) {
                MenuBarRow(
                    title: "位置服务",
                    subtitle: permissions.canReadWiFiName ? "已允许，仅用于读取 Wi‑Fi 名称" : "需要权限才能读取 Wi‑Fi 名称",
                    icon: "location.fill"
                ) {
                    if permissions.canReadWiFiName {
                        Label("已允许", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundStyle(.green)
                    } else {
                        Button(locationPermissionButtonTitle) {
                            if permissions.isDenied {
                                openLocationSettings()
                            } else {
                                router.route = .permission
                            }
                        }
                        .buttonStyle(LocusSecondaryButtonStyle())
                        .disabled(permissions.isRequestingLocationPermission)
                    }
                }
                Divider()
                MenuBarRow(title: "系统通知", subtitle: notificationSubtitle, icon: "bell") {
                    switch model.notificationAuthorizationStatus {
                    case .authorized, .provisional, .ephemeral:
                        Label("已允许", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundStyle(.green)
                    case .denied:
                        Button("打开设置", action: openNotificationSettings)
                            .buttonStyle(LocusSecondaryButtonStyle())
                    default:
                        Button("请求权限") {
                            Task { _ = await model.requestNotificationPermission() }
                        }
                        .buttonStyle(LocusSecondaryButtonStyle())
                    }
                }
            } }
        }
    }

    private var aboutSection: some View {
        MenuBarSection(title: "Locus") {
            LocusCard { VStack(spacing: 0) {
                Button {
                    router.route = .activity
                } label: {
                    MenuBarRow(title: "活动记录", subtitle: "查看最近的网络和规则操作", icon: "list.bullet.rectangle") {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(LocusRowButtonStyle())
                Divider()
                MenuBarRow(title: "版本", subtitle: "所有数据仅保存在此 Mac", icon: "info.circle") {
                    Text(versionText)
                        .font(.system(size: 10.5, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Divider()
                Button(action: onQuit) {
                    MenuBarRow(title: "退出 Locus", icon: "power") {
                        Image(systemName: "power")
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(LocusRowButtonStyle())
            } }
        }
    }

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return version ?? "开发版本"
    }

    private var locationPermissionButtonTitle: String {
        if permissions.isRequestingLocationPermission {
            return "等待系统…"
        }
        return permissions.isDenied ? "打开设置" : "允许"
    }

    private func openLocationSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") else { return }
        NSWorkspace.shared.open(url)
    }

    private var notificationSubtitle: String {
        switch model.notificationAuthorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return "规则应用成功后显示通知"
        case .denied:
            return "已拒绝，可在系统设置中更改"
        default:
            return "允许规则应用后显示通知"
        }
    }

    private func openNotificationSettings() {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.locusapp.Locus"
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications?id=\(bundleID)") else { return }
        NSWorkspace.shared.open(url)
    }
}
