import AppKit
import SwiftUI

struct MenuBarPermissionView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var permissions: PermissionService
    @EnvironmentObject private var router: PanelRouter

    var body: some View {
        ZStack {
            MenuBarHomeView()
                .disabled(true)
                .blur(radius: 1.2)

            Color.black.opacity(0.28).ignoresSafeArea()

            VStack(spacing: 13) {
                LocusIconTile(symbol: "location.fill", color: .orange, size: 46)

                VStack(spacing: 5) {
                    Text("允许 Locus 读取 Wi‑Fi 名称")
                        .font(.system(size: 15, weight: .bold))
                    Text("请在 macOS 系统提示中允许位置访问。\nLocus 不会读取或保存实际位置。")
                        .font(.system(size: 11.5))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 8) {
                    Button("取消", action: router.showHome)
                        .buttonStyle(LocusSecondaryButtonStyle())
                    Button {
                        if permissions.isDenied {
                            openLocationSettings()
                        } else {
                            model.requestLocationPermission()
                        }
                    } label: {
                        Text("没有看到提示？打开系统设置")
                    }
                    .buttonStyle(LocusPrimaryButtonStyle())
                    .disabled(permissions.isRequestingLocationPermission)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 17)
            .frame(width: 286)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(nsColor: .windowBackgroundColor))
                    .shadow(color: .black.opacity(0.24), radius: 22, y: 8)
            )
        }
        .onChange(of: permissions.locationStatus) { _, status in
            if status == .authorized || status == .authorizedAlways { router.showHome() }
        }
    }

    private func openLocationSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") else { return }
        NSWorkspace.shared.open(url)
    }
}
