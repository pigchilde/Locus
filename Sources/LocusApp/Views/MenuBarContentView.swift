import AppKit
import SwiftUI

struct MenuBarContentView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
                .padding(.horizontal, 10)
            volumeControl
            Divider()
                .padding(.horizontal, 10)
            actions
        }
        .frame(width: 300)
        .padding(.vertical, 8)
    }

    private var header: some View {
        HStack(spacing: 11) {
            LocusAppIcon(size: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text("当前网络")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Text(model.currentSSID ?? "无法读取 Wi‑Fi 名称")
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                HStack(spacing: 5) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)
                    Text(statusText)
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var volumeControl: some View {
        HStack(spacing: 9) {
            Image(systemName: "speaker.wave.2")
                .foregroundStyle(.secondary)
            Slider(value: Binding(
                get: { model.currentVolume },
                set: model.setCurrentVolumeInteractively
            ), in: 0...1)
            Text(model.currentVolume, format: .percent.precision(.fractionLength(0)))
                .font(.system(size: 10.5, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .trailing)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 12)
    }

    private var actions: some View {
        VStack(spacing: 2) {
            if model.isPaused {
                menuButton("恢复自动控制", symbol: "play.fill") {
                    model.resumeAutomation()
                }
            } else {
                menuButton("暂停自动控制 1 小时", symbol: "pause.fill") {
                    model.pause(for: 60 * 60)
                }
            }

            if model.currentSSID != nil, model.matchingRule == nil {
                menuButton("为当前网络添加规则", symbol: "plus") {
                    showMainWindow()
                    model.addCurrentNetworkRule()
                }
            }

            menuButton("打开 Wi‑Fi 规则…", symbol: "slider.horizontal.3") {
                showMainWindow()
            }

            Divider()
                .padding(.vertical, 4)

            menuButton("退出 Locus", symbol: "power") {
                NSApp.terminate(nil)
            }
        }
        .padding(.horizontal, 7)
        .padding(.top, 6)
    }

    private func menuButton(
        _ title: String,
        symbol: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.clear)
    }

    private func showMainWindow() {
        openWindow(id: "main")
        NSApp.activate(ignoringOtherApps: true)
    }

    private var statusText: String {
        if let rule = model.matchingRule {
            return "“\(rule.displayName)”规则已匹配"
        }
        return model.runtimeState.shortLabel
    }

    private var statusColor: Color {
        switch model.runtimeState {
        case .ready, .applying: return .green
        case .starting, .paused, .noMatchingRule: return .orange
        case .waitingForPermission, .error: return .red
        }
    }
}
