import LocusCore
import SwiftUI

struct MenuBarActivityView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var router: PanelRouter

    var body: some View {
        VStack(spacing: 0) {
            MenuBarHeader(title: "最近活动", onBack: router.showHome)
            if model.activities.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 30, weight: .light)).foregroundStyle(.secondary)
                    Text("暂无活动").font(.system(size: 14, weight: .medium))
                    Text("连接网络或应用规则后，记录会显示在这里。")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: LocusDesign.sectionSpacing) {
                        if !todayActivities.isEmpty {
                            MenuBarSection(title: "今天") { LocusCard { activityList(todayActivities) } }
                        }
                        if !earlierActivities.isEmpty {
                            MenuBarSection(title: "更早") { LocusCard { activityList(earlierActivities) } }
                        }
                        Text("最近 20 条记录 · 仅保存在此 Mac")
                            .font(.system(size: 10)).foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                    }
                    .padding(.horizontal, LocusDesign.pagePadding)
                    .padding(.bottom, 14)
                }
            }
        }
    }

    private func activityRow(_ activity: ActivityRecord) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: symbol(activity.kind))
                .font(.system(size: 13))
                .foregroundStyle(activity.kind == .warning ? Color.orange : activity.kind == .ruleApplied ? .green : .secondary)
                .frame(width: 17)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(activity.title)
                        .font(.system(size: 12, weight: .medium))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Text(locusRelativeTime(from: activity.date))
                        .font(.system(size: 9)).foregroundStyle(.secondary)
                        .fixedSize()
                }
                Text(activity.detail)
                    .font(.system(size: 10)).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }

    private func symbol(_ kind: ActivityKind) -> String {
        switch kind {
        case .ruleApplied: return "checkmark.circle"
        case .networkChanged: return "network"
        case .outputChanged: return "speaker.wave.2"
        case .warning: return "exclamationmark.circle"
        }
    }

    private var todayActivities: [ActivityRecord] {
        model.activities.prefix(20).filter { Calendar.current.isDateInToday($0.date) }
    }
    private var earlierActivities: [ActivityRecord] {
        model.activities.prefix(20).filter { !Calendar.current.isDateInToday($0.date) }
    }
    private func activityList(_ activities: [ActivityRecord]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(activities.enumerated()), id: \.element.id) { index, activity in
                if index > 0 { Divider().padding(.leading, 26) }
                activityRow(activity)
            }
        }
    }
}
