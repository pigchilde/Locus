import AppKit
import SwiftUI

@main
struct LocusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()

    var body: some Scene {
        Window("Locus", id: "main") {
            RootView()
                .environmentObject(model)
                .environmentObject(model.permissions)
                .frame(minWidth: 780, minHeight: 620)
                .task {
                    applyDockIcon()
                    model.start()
                }
                .alert(
                    "Locus",
                    isPresented: Binding(
                        get: { model.lastErrorMessage != nil },
                        set: { if !$0 { model.lastErrorMessage = nil } }
                    )
                ) {
                    Button("好") { model.lastErrorMessage = nil }
                } message: {
                    Text(model.lastErrorMessage ?? "")
                }
        }
        .defaultSize(width: 1_020, height: 680)
        .defaultPosition(.center)
        .windowToolbarStyle(.unified)

        MenuBarExtra(
            isInserted: Binding(
                get: { model.preferences.showMenuBar },
                set: { model.setShowMenuBar($0) }
            )
        ) {
            MenuBarContentView()
                .environmentObject(model)
        } label: {
            ZStack {
                LocusMark()
                    .stroke(.primary, style: StrokeStyle(lineWidth: 1.35, lineCap: .round, lineJoin: .round))
                Circle()
                    .fill(.primary)
                    .frame(width: 2.9, height: 2.9)
            }
                .frame(width: 17, height: 17)
        }
        .menuBarExtraStyle(.window)
    }

    private func applyDockIcon() {
        guard
            let iconURL = Bundle.main.url(forResource: "LocusDockIcon", withExtension: "png"),
            let icon = NSImage(contentsOf: iconURL)
        else { return }

        NSApplication.shared.applicationIconImage = icon
    }
}
