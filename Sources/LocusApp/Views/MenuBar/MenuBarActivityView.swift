import LocusCore
import SwiftUI

struct MenuBarActivityView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var router: PanelRouter

    var body: some View {
        VStack(spacing: 0) {
            MenuBarHeader(title: "最近活动", onBack: router.showHome)

            if model.activities.isEmpty {
                ContentUnavailableView(
                    "暂无活动",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("连接 Wi‑Fi 或应用规则后，记录会显示在这里。")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: LocusDesign.sectionSpacing) {
                        if !todayActivities.isEmpty {
                            MenuBarSection(title: "今天") {
                                LocusCard { activityList(todayActivities) }
                            }
                        }
                        if !earlierActivities.isEmpty {
                            MenuBarSection(title: "更早") {
                                LocusCard { activityList(earlierActivities) }
                            }
                        }
                    }
                    .padding(.horizontal, LocusDesign.pagePadding)
                    .padding(.vertical, 6)
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private func activityRow(_ activity: ActivityRecord) -> some View {
        HStack(alignment: .top, spacing: 10) {
            LocusIconTile(symbol: symbol(activity.kind), color: color(activity.kind), size: 36)
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline) {
                    Text(activity.title)
                        .font(.system(size: 12.5, weight: .medium))
                    Spacer(minLength: 8)
                    Text(locusRelativeTime(from: activity.date))
                        .font(.system(size: 9.5))
                        .foregroundStyle(.tertiary)
                }
                Text(activity.detail)
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(minHeight: 58)
        .accessibilityElement(children: .combine)
    }

    private func symbol(_ kind: ActivityKind) -> String {
        switch kind {
        case .ruleApplied: return "checkmark.circle.fill"
        case .networkChanged: return "wifi"
        case .outputChanged: return "speaker.wave.2.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }

    private func color(_ kind: ActivityKind) -> Color {
        switch kind {
        case .ruleApplied: return .green
        case .warning: return .orange
        default: return .secondary
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
                if index > 0 { Divider() }
                activityRow(activity)
            }
        }
    }
}
