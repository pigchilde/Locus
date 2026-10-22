import AppKit
import LocusCore
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private lazy var model = makeAppModel()
    private let router = PanelRouter()
    private let popover = NSPopover()
    private var statusItem: NSStatusItem?
    private var previewWindow: NSWindow?

    private var isPreviewMode: Bool {
        ProcessInfo.processInfo.arguments.contains("--preview-window")
            || ProcessInfo.processInfo.environment["LOCUS_PREVIEW"] == "1"
            || Bundle.main.object(forInfoDictionaryKey: "LocusPreviewMode") as? Bool == true
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        guard !isPreviewMode else { return }

        guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return }

        let currentProcessIdentifier = ProcessInfo.processInfo.processIdentifier
        if let existingApplication = NSRunningApplication
            .runningApplications(withBundleIdentifier: bundleIdentifier)
            .first(where: { $0.processIdentifier != currentProcessIdentifier }) {
            existingApplication.activate(options: [.activateAllWindows])
            NSApplication.shared.terminate(nil)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if isPreviewMode {
            model.start()
            if let outputURL = previewCaptureOutput() {
                capturePreviewImage(route: previewRoute(), outputURL: outputURL)
            } else {
                showPreviewWindow(route: previewRoute())
            }
        } else {
            model.start()
            configurePopover()
            installStatusItem()
            installApplicationMenu()
        }
    }

    private func makeAppModel() -> AppModel {
        guard isPreviewMode else { return AppModel() }
        let preview = LocusPreviewState(scenario: ProcessInfo.processInfo.environment["LOCUS_PREVIEW_SCENARIO"] ?? "ready")
        return AppModel(repository: makePreviewRepository(preview), preview: preview)
    }

    /// Preview launches run on throwaway sample data so that taking screenshots
    /// never writes real state or applies rules to system audio.
    private func makePreviewRepository(_ preview: LocusPreviewState) -> StateRepository {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocusPreviewState-\(UUID().uuidString).json")
        let repository = StateRepository(fileURL: fileURL)
        var state = preview.persisted
        state.preferences.appearance = ProcessInfo.processInfo.environment["LOCUS_PREVIEW_APPEARANCE"] == "dark" ? .dark : .light
        try? repository.save(state)
        return repository
    }

    private func previewRoute() -> PanelRoute {
        let arguments = ProcessInfo.processInfo.arguments
        if let route = ProcessInfo.processInfo.environment["LOCUS_PREVIEW_ROUTE"] {
            return routeForPreview(route)
        }
        guard let flagIndex = arguments.firstIndex(of: "--preview-route"),
              flagIndex + 1 < arguments.count else {
            return .home
        }
        return routeForPreview(arguments[flagIndex + 1])
    }

    private func routeForPreview(_ route: String) -> PanelRoute {
        switch route {
        case "rule", "delete":
            return model.rules.first(where: { !$0.isFallback }).map { PanelRoute.rule($0.id) } ?? .home
        case "fallback": return model.rules.first(where: \.isFallback).map { .rule($0.id) } ?? .home
        case "wifiRule":
            return model.rules.first(where: { !$0.isFallback && $0.kind == .wifi }).map { .rule($0.id) } ?? .home
        case "addRule": return .addRule
        case "settings": return .settings
        case "activity": return .activity
        case "permission": return .permission
        default: return .home
        }
    }

    private func previewCaptureOutput() -> URL? {
        if let path = ProcessInfo.processInfo.environment["LOCUS_PREVIEW_CAPTURE"] {
            return URL(fileURLWithPath: path)
        }
        let arguments = ProcessInfo.processInfo.arguments
        guard let flagIndex = arguments.firstIndex(of: "--preview-capture"),
              flagIndex + 1 < arguments.count else { return nil }
        return URL(fileURLWithPath: arguments[flagIndex + 1])
    }

    /// Renders the preview route off-screen and writes a PNG. Capturing the
    /// app's own view hierarchy avoids the Screen Recording permission that
    /// `screencapture` requires for window capture.
    private func capturePreviewImage(route: PanelRoute, outputURL: URL) {
        let size = NSSize(width: LocusDesign.panelWidth, height: LocusDesign.panelHeight)
        router.route = route
        let rootView = MenuBarRootView {
            NSApplication.shared.terminate(nil)
        }
        .environmentObject(model)
        .environmentObject(model.permissions)
        .environmentObject(router)
        .environment(\.controlActiveState, .active)
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless], backing: .buffered, defer: false
        )
        window.contentViewController = NSHostingController(rootView: rootView)
        window.appearance = NSApp.appearance
        // Attaching to a window runs SwiftUI lifecycle/layout without presenting UI.
        let contentView = window.contentView!
        contentView.frame = NSRect(origin: .zero, size: size)
        contentView.layoutSubtreeIfNeeded()
        previewWindow = window

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            contentView.layoutSubtreeIfNeeded()
            contentView.displayIfNeeded()
            let scale: CGFloat = 2
            guard let rep = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: Int(size.width * scale),
                pixelsHigh: Int(size.height * scale),
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .calibratedRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            ) else {
                FileHandle.standardError.write("failed to allocate bitmap\n".data(using: .utf8)!)
                NSApplication.shared.terminate(nil)
                return
            }
            rep.size = size
            contentView.cacheDisplay(in: NSRect(origin: .zero, size: size), to: rep)

            if let data = rep.representation(using: .png, properties: [:]) {
                do {
                    try data.write(to: outputURL)
                    print("captured: \(outputURL.path)")
                } catch {
                    FileHandle.standardError.write("write failed: \(error)\n".data(using: .utf8)!)
                }
            } else {
                FileHandle.standardError.write("failed to encode PNG\n".data(using: .utf8)!)
            }
            NSApplication.shared.terminate(nil)
        }
    }

    private func showPreviewWindow(route: PanelRoute) {
        router.route = route

        let window: NSWindow
        let rootView = MenuBarRootView {
            NSApplication.shared.terminate(nil)
        }
        .environmentObject(model)
        .environmentObject(model.permissions)
        .environmentObject(router)

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 368, height: 580),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Locus Preview"
        window.contentViewController = NSHostingController(rootView: rootView)

        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
        previewWindow = window
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 368, height: 580)
        popover.delegate = self

        let rootView = MenuBarRootView {
            NSApplication.shared.terminate(nil)
        }
        .environmentObject(model)
        .environmentObject(model.permissions)
        .environmentObject(router)

        popover.contentViewController = NSHostingController(rootView: rootView)
    }

    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.autosaveName = "com.locusapp.Locus.statusItem"
        item.isVisible = true

        if let button = item.button {
            button.image = makeStatusBarIcon()
            button.imagePosition = .imageOnly
            button.toolTip = "Locus"
            button.target = self
            button.action = #selector(togglePopover)
            button.sendAction(on: [.leftMouseUp])
        }

        statusItem = item
    }

    private func installApplicationMenu() {
        let mainMenu = NSMenu()
        let applicationItem = NSMenuItem()
        mainMenu.addItem(applicationItem)

        let applicationMenu = NSMenu()
        let settingsItem = NSMenuItem(
            title: "设置…",
            action: #selector(showSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        applicationMenu.addItem(settingsItem)
        applicationMenu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "退出 Locus",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = NSApplication.shared
        applicationMenu.addItem(quitItem)

        applicationItem.submenu = applicationMenu
        NSApplication.shared.mainMenu = mainMenu
    }

    @objc private func showSettings() {
        router.route = .settings
        guard !popover.isShown, let button = statusItem?.button else { return }
        model.refreshSnapshot()
        NSApplication.shared.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
        button.highlight(true)
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }

        if popover.isShown {
            popover.performClose(nil)
            return
        }

        router.showHome()
        model.refreshSnapshot()
        NSApplication.shared.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
        button.highlight(true)
    }

    func popoverDidClose(_ notification: Notification) {
        statusItem?.button?.highlight(false)
        router.showHome()
    }

    private func makeStatusBarIcon() -> NSImage {
        let image = LocusBrand.menuBarIcon.copy() as! NSImage
        image.size = NSSize(width: 18, height: 18)
        image.isTemplate = true
        return image
    }
}
