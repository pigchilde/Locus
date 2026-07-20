import AppKit
import SwiftUI

enum SidebarPage: String, CaseIterable, Identifiable {
    case overview
    case rules
    case preferences

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: return "概览"
        case .rules: return "Wi‑Fi 规则"
        case .preferences: return "偏好设置"
        }
    }

    var symbol: String {
        switch self {
        case .overview: return "square.grid.2x2"
        case .rules: return "list.bullet"
        case .preferences: return "gearshape"
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selection: SidebarPage = .rules

    private let compactBreakpoint: CGFloat = 980

    var body: some View {
        GeometryReader { proxy in
            Group {
                if proxy.size.width < compactBreakpoint {
                    compactLayout
                } else {
                    regularLayout
                }
            }
        }
        .sheet(isPresented: $model.isShowingAddRule) {
            AddRuleSheet()
                .environmentObject(model)
        }
    }

    private var regularLayout: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 190, ideal: 215, max: 240)
        } detail: {
            pageContent
                .navigationTitle(selection.title)
                .toolbar { ruleActions }
        }
        .navigationSplitViewStyle(.balanced)
    }

    private var compactLayout: some View {
        NavigationStack {
            pageContent
                .navigationTitle(selection.title)
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        Menu {
                            ForEach(SidebarPage.allCases) { page in
                                Button {
                                    selection = page
                                } label: {
                                    Label(page.title, systemImage: page.symbol)
                                }
                            }
                        } label: {
                            Label("切换页面", systemImage: selection.symbol)
                        }
                        .help("切换页面")
                    }

                    ruleActions
                }
        }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            brandHeader
            List(SidebarPage.allCases, selection: $selection) { page in
                Label(page.title, systemImage: page.symbol)
                    .tag(page)
            }
            .listStyle(.sidebar)
            statusFooter
        }
    }

    @ViewBuilder
    private var pageContent: some View {
        switch selection {
        case .overview:
            OverviewView()
        case .rules:
            RulesView()
        case .preferences:
            PreferencesView()
        }
    }

    @ToolbarContentBuilder
    private var ruleActions: some ToolbarContent {
        if selection == .rules {
            ToolbarItemGroup {
                Button {
                    model.refresh()
                } label: {
                    Label("刷新", systemImage: "arrow.clockwise")
                }
                .help("刷新当前网络和音频设备")

                Button {
                    model.addCurrentNetworkRule()
                } label: {
                    Label("添加规则", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var brandHeader: some View {
        HStack(spacing: 10) {
            LocusAppIcon(size: 32)
            VStack(alignment: .leading, spacing: 1) {
                Text("Locus")
                    .font(.system(size: 14, weight: .semibold))
                Text("随位置，听见恰好的声音")
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    private var statusFooter: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 7, height: 7)
            Text(model.runtimeState.shortLabel)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var statusColor: Color {
        switch model.runtimeState {
        case .ready, .applying: return .green
        case .starting, .paused, .noMatchingRule: return .orange
        case .waitingForPermission, .error: return .red
        }
    }
}
