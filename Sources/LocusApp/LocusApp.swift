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
                .background {
                    MainWindowAccessor { window in
                        appDelegate.registerMainWindow(window)
                    }
                }
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
    }

    private func applyDockIcon() {
        guard
            let iconURL = Bundle.main.url(forResource: "LocusDockIcon", withExtension: "png"),
            let icon = NSImage(contentsOf: iconURL)
        else { return }

        NSApplication.shared.applicationIconImage = icon
    }
}

private struct MainWindowAccessor: NSViewRepresentable {
    let onWindowAvailable: (NSWindow) -> Void

    func makeNSView(context: Context) -> WindowObservingView {
        WindowObservingView(onWindowAvailable: onWindowAvailable)
    }

    func updateNSView(_ nsView: WindowObservingView, context: Context) {
        nsView.onWindowAvailable = onWindowAvailable
        nsView.reportWindowIfAvailable()
    }
}

private final class WindowObservingView: NSView {
    var onWindowAvailable: (NSWindow) -> Void

    init(onWindowAvailable: @escaping (NSWindow) -> Void) {
        self.onWindowAvailable = onWindowAvailable
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        reportWindowIfAvailable()
    }

    func reportWindowIfAvailable() {
        guard let window else { return }
        onWindowAvailable(window)
    }
}
