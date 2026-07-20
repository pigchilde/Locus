import LocusCore
import SwiftUI

struct RulesView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        GeometryReader { proxy in
            let isNarrow = proxy.size.width < 860

            HSplitView {
                ruleList
                    .frame(
                        minWidth: isNarrow ? 220 : 250,
                        idealWidth: isNarrow ? 240 : 290,
                        maxWidth: isNarrow ? 270 : 330
                    )

                if let rule = model.rule(withID: model.selectedRuleID) {
                    RuleDetailView(ruleID: rule.id)
                        .frame(
                            minWidth: isNarrow ? 460 : 500,
                            maxWidth: .infinity,
                            maxHeight: .infinity
                        )
                } else {
                    ContentUnavailableView {
                        Label("选择一条规则", systemImage: "wifi")
                    } description: {
                        Text("从左侧选择规则，或为当前 Wi‑Fi 创建一条新规则。")
                    } actions: {
                        Button("添加规则") {
                            model.addCurrentNetworkRule()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(
                        minWidth: isNarrow ? 460 : 500,
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
                }
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var ruleList: some View {
        VStack(spacing: 0) {
            HStack {
                Text("已保存的网络")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 14)
            .padding(.bottom, 7)

            List(selection: $model.selectedRuleID) {
                ForEach(model.rules) { rule in
                    RuleRow(
                        rule: rule,
                        isCurrent: !rule.isFallback && model.currentSSID == rule.ssid
                    )
                    .tag(rule.id)
                    .contextMenu {
                        Button("立即应用") {
                            model.applyRuleNow(rule)
                        }
                        if !rule.isFallback {
                            Divider()
                            Button("删除规则", role: .destructive) {
                                model.deleteRule(id: rule.id)
                            }
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
        }
        .background(Color(nsColor: .underPageBackgroundColor).opacity(0.45))
    }
}

private struct RuleRow: View {
    let rule: WiFiRule
    let isCurrent: Bool

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color.primary.opacity(0.055))
                Image(systemName: "wifi")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isCurrent ? Color.accentColor : .secondary)
            }
            .frame(width: 29, height: 29)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(rule.displayName)
                        .font(.system(size: 12.5, weight: .semibold))
                        .lineLimit(1)
                    if !rule.isEnabled {
                        Text("已停用")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 6)
            Text(rule.targetVolume, format: .percent.precision(.fractionLength(0)))
                .font(.system(size: 10.5, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var subtitle: String {
        if isCurrent {
            return "当前已连接 · \(rule.outputDeviceName ?? "保持当前设备")"
        }
        if rule.isFallback {
            return "未保存网络的默认规则"
        }
        return rule.outputDeviceName ?? "保持当前设备"
    }
}
