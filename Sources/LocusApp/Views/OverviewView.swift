import LocusCore
import SwiftUI

struct OverviewView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var permissions: PermissionService

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if !permissions.canReadWiFiName {
                    permissionBanner
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(eyebrow)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text(heading)
                        .font(.system(size: 25, weight: .bold))
                    Text(subheading)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                currentStatusCard
                stats

                VStack(alignment: .leading, spacing: 0) {
                    Text("最近活动")
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.bottom, 6)
                    if model.activities.isEmpty {
                        ContentUnavailableView(
                            "还没有活动",
                            systemImage: "clock",
                            description: Text("连接一个已保存的 Wi‑Fi 后，规则记录会显示在这里。")
                        )
                        .frame(height: 170)
                    } else {
                        ForEach(model.activities.prefix(8)) { activity in
                            ActivityRow(activity: activity)
                            Divider()
                        }
                    }
                }
            }
            .frame(maxWidth: 680, alignment: .leading)
            .padding(34)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var eyebrow: String {
        switch model.runtimeState {
        case .ready: return "一切正常"
        case .applying: return "正在调整"
        case .paused: return "暂时暂停"
        case .waitingForPermission: return "需要完成设置"
        case .noMatchingRule: return "尚未创建规则"
        case .starting: return "正在启动"
        case .error: return "需要处理"
        }
    }

    private var heading: String {
        model.matchingRule == nil ? "为这个位置设置声音。" : "声音，已经就位。"
    }

    private var subheading: String {
        if let rule = model.matchingRule {
            return "Locus 正在使用“\(rule.displayName)”规则，并会在网络变化后自动恢复合适的音量。"
        }
        return "为当前 Wi‑Fi 创建第一条规则，之后每次连接都会自动恢复音量。"
    }

    private var permissionBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "location.fill")
                .foregroundStyle(.blue)
                .frame(width: 26, height: 26)
                .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 7))
            VStack(alignment: .leading, spacing: 2) {
                Text("允许 Locus 读取当前 Wi‑Fi 名称")
                    .font(.system(size: 12, weight: .semibold))
                Text("macOS 要求位置权限才能提供 SSID；Locus 不读取或保存实际位置。")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(permissionButtonTitle) {
                if permissions.isDenied {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") {
                        NSWorkspace.shared.open(url)
                    }
                } else {
                    model.requestLocationPermission()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(permissions.isRequestingLocationPermission)
        }
        .padding(13)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 11))
        .overlay(
            RoundedRectangle(cornerRadius: 11)
                .stroke(.separator.opacity(0.7), lineWidth: 0.5)
        )
    }

    private var permissionButtonTitle: String {
        if permissions.isRequestingLocationPermission {
            return "等待系统授权…"
        }
        return permissions.isDenied ? "打开设置" : "允许"
    }

    private var currentStatusCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "wifi")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 13))
            VStack(alignment: .leading, spacing: 3) {
                Text("当前网络")
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)
                Text(model.currentSSID ?? "无法读取 Wi‑Fi 名称")
                    .font(.system(size: 16, weight: .semibold))
                Text(currentDeviceText)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(model.currentVolume, format: .percent.precision(.fractionLength(0)))
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                Text("系统音量")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.separator.opacity(0.65), lineWidth: 0.5)
        )
    }

    private var currentDeviceText: String {
        let ruleName = model.matchingRule?.displayName ?? "没有匹配规则"
        let deviceName = model.currentDevice?.name ?? "未知输出设备"
        return "\(ruleName) · \(deviceName)"
    }

    private var stats: some View {
        HStack(spacing: 10) {
            StatView(label: "自动控制", value: model.preferences.automationEnabled ? "已开启" : "已关闭")
            StatView(label: "已保存规则", value: "\(model.rules.filter { !$0.isFallback }.count) 个")
            StatView(label: "最近记录", value: "\(model.activities.count) 条")
        }
    }
}

private struct StatView: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 10.5))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 13, weight: .semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(13)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.separator.opacity(0.65), lineWidth: 0.5)
        )
    }
}

private struct ActivityRow: View {
    let activity: ActivityRecord

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 27, height: 27)
                .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 7))
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.system(size: 11.5, weight: .medium))
                Text(activity.detail)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(activity.date, style: .relative)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
    }

    private var symbol: String {
        switch activity.kind {
        case .ruleApplied: return "speaker.wave.2"
        case .networkChanged: return "wifi"
        case .outputChanged: return "hifispeaker"
        case .warning: return "exclamationmark.triangle"
        }
    }

    private var color: Color {
        activity.kind == .warning ? .orange : .blue
    }
}
