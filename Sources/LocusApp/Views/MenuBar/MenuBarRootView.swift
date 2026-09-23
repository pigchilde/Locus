import SwiftUI

enum PanelRoute: Hashable {
    case home
    case rule(UUID)
    case addRule
    case settings
    case activity
    case permission
}

@MainActor
final class PanelRouter: ObservableObject {
    @Published var route: PanelRoute = .home

    func showHome() {
        route = .home
    }
}

struct MenuBarRootView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var router: PanelRouter
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let onQuit: () -> Void

    var body: some View {
        Group {
            switch router.route {
            case .home:
                MenuBarHomeView()
            case .rule(let id):
                MenuBarRuleDetailView(ruleID: id)
            case .addRule:
                MenuBarAddRuleView()
            case .settings:
                MenuBarSettingsView(onQuit: onQuit)
            case .activity:
                MenuBarActivityView()
            case .permission:
                MenuBarPermissionView()
            }
        }
        .id(router.route)
        .transition(reduceMotion ? .opacity : .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
        .frame(width: LocusDesign.panelWidth, height: LocusDesign.panelHeight)
        .background(LocusPanelBackground())
        .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: router.route)
        .onExitCommand {
            if router.route != .home {
                router.showHome()
            }
        }
    }
}
