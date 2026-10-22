import AppKit
import SwiftUI

struct MenuBarPermissionView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var permissions: PermissionService
    @EnvironmentObject private var router: PanelRouter

    var body: some View {
        VStack(spacing: 0) {
            MenuBarHeader(title: "Wi-Fi 名称", onBack: router.showHome)
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 14) {
                        Image(systemName: "location")
                            .font(.system(size: 25, weight: .regular))
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 48, height: 48)
                            .background(Color.accentColor.opacity(0.08), in: Circle())
                        Text("让声音跟随你的网络")
                            .font(.system(size: 17, weight: .semibold))
                        Text("macOS 需要位置权限，才能向 Locus 提供当前 Wi-Fi 名称。允许后，即可自动匹配对应的声音规则。")
                            .font(.system(size: 12)).foregroundStyle(.secondary)
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 6)
                    .padding(.top, 12)
                    LocusCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("仅用于识别当前 Wi-Fi", systemImage: "wifi")
                            Label("不保存或上传实际位置", systemImage: "hand.raised")
                            Label("有线网络无需此权限", systemImage: "cable.connector")
                        }
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 16)
                    }
                    if permissions.isRequestingLocationPermission {
                        Label("请在系统提示中选择允许。", systemImage: "info.circle")
                            .font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                    if permissions.isDenied {
                        Text("请在“系统设置 → 隐私与安全性 → 定位服务”中允许 Locus。")
                            .font(.system(size: 11)).foregroundStyle(.secondary)
                            .lineSpacing(4)
                    }
                }
                .padding(.horizontal, LocusDesign.pagePadding)
                .padding(.bottom, 20)
            }
            Divider()
            HStack {
                Button("稍后", action: router.showHome)
                    .buttonStyle(LocusSecondaryButtonStyle())
                Spacer()
                if permissions.isRequestingLocationPermission {
                    ProgressView().controlSize(.small)
                }
                Button(permissions.isDenied ? "打开系统设置" : "允许读取") {
                    if permissions.isDenied { openLocationSettings() }
                    else { model.requestLocationPermission() }
                }
                .buttonStyle(LocusPrimaryButtonStyle())
                .disabled(permissions.isRequestingLocationPermission)
            }
            .padding(.horizontal, LocusDesign.pagePadding)
            .frame(height: LocusDesign.bottomBarHeight)
        }
        .onChange(of: permissions.locationStatus) { _, status in
            if status == .authorized || status == .authorizedAlways { router.showHome() }
        }
    }

    private func openLocationSettings() {
        guard !model.isPreview,
              let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") else { return }
        NSWorkspace.shared.open(url)
    }
}
