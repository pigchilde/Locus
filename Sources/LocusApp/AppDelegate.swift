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
        return AppModel(repository: makePreviewRepository())
    }

    /// Preview launches run on throwaway sample data so that taking screenshots
    /// never writes real state or applies rules to system audio.
    private func makePreviewRepository() -> StateRepository {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocusPreviewState-\(UUID().uuidString).json")
        let repository = StateRepository(fileURL: fileURL)
        let now = Date()
        let previewAppearance: AppearanceMode = ProcessInfo.processInfo.environment["LOCUS_PREVIEW_APPEARANCE"] == "dark"
            ? .dark
            : .light
        try? repository.save(PersistedState(
            rules: [
                WiFiRule(
                    ssid: "Home-5G",
                    targetVolume: 0.55,
                    transition: .oneSecond
                ),
                WiFiRule(
                    ssid: "Office-Meeting",
                    outputDeviceUID: "preview-device-unavailable",
                    outputDeviceName: "会议音响",
                    targetVolume: 0.3,
                    mutePolicy: .mute,
                    transition: .threeSeconds
                ),
                .defaultFallback,
            ],
            preferences: AppPreferences(
                automationEnabled: true,
                switchDelay: 1,
                useFallbackRule: false,
                appearance: previewAppearance
            ),
            activities: [
                ActivityRecord(
                    kind: .ruleApplied,
                    title: "已应用 Home-5G",
                    detail: "系统音量已调整至 55%",
                    date: now.addingTimeInterval(-95)
                ),
                ActivityRecord(
                    kind: .networkChanged,
                    title: "已连接 Home-5G",
                    detail: "正在查找匹配的音量规则",
                    date: now.addingTimeInterval(-100)
                ),
                ActivityRecord(
                    kind: .outputChanged,
                    title: "输出设备已切换",
                    detail: "MacBook Pro 扬声器",
                    date: now.addingTimeInterval(-3600)
                ),
                ActivityRecord(
                    kind: .warning,
                    title: "操作未完成",
                    detail: "目标音频设备当前不可用",
                    date: now.addingTimeInterval(-86400)
                ),
            ]
        ))
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
        case "rule":
            return model.rules.first(where: { !$0.isFallback }).map { PanelRoute.rule($0.id) } ?? .home
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
        let size: NSSize
        let contentView: NSView
        let isDeleteConfirmationPreview = ProcessInfo.processInfo.environment["LOCUS_PREVIEW_ROUTE"] == "delete"
        if isDeleteConfirmationPreview,
                  let rule = model.rules.first(where: { !$0.isFallback }) {
            size = NSSize(width: 368, height: 580)
            contentView = NSHostingView(
                rootView: MenuBarRuleDetailView(
                    ruleID: rule.id,
                    initiallyConfirmingDelete: true
                )
                .frame(width: 368, height: 580)
                .background(Color(nsColor: .windowBackgroundColor))
                .environmentObject(model)
                .environmentObject(router)
            )
        } else {
            size = NSSize(width: 368, height: 580)
            router.route = route
            contentView = NSHostingView(
                rootView: MenuBarRootView {
                    NSApplication.shared.terminate(nil)
                }
                .environmentObject(model)
                .environmentObject(model.permissions)
                .environmentObject(router)
            )
        }
        contentView.frame = NSRect(origin: .zero, size: size)
        contentView.layoutSubtreeIfNeeded()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let scale = NSScreen.main?.backingScaleFactor ?? 2
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
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApplication.shared.activate(ignoringOtherApps: true)
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
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApplication.shared.activate(ignoringOtherApps: true)
        button.highlight(true)
    }

    func popoverDidClose(_ notification: Notification) {
        statusItem?.button?.highlight(false)
        router.showHome()
    }

    private func makeStatusBarIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let sx = rect.width / 64
            let sy = rect.height / 64
            func point(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
                NSPoint(x: rect.minX + x * sx, y: rect.maxY - y * sy)
            }

            let mark = NSBezierPath()
            mark.move(to: point(32, 11.5))
            mark.curve(
                to: point(14.5, 30.04),
                controlPoint1: point(22.33, 11.5),
                controlPoint2: point(14.5, 19.75)
            )
            mark.curve(
                to: point(32, 54.88),
                controlPoint1: point(14.5, 38.16),
                controlPoint2: point(20.85, 46.51)
            )
            mark.curve(
                to: point(49.5, 30.04),
                controlPoint1: point(43.15, 46.51),
                controlPoint2: point(49.5, 38.16)
            )
            mark.curve(
                to: point(32, 11.5),
                controlPoint1: point(49.5, 19.75),
                controlPoint2: point(41.68, 11.5)
            )
            mark.close()
            mark.move(to: point(21.75, 34.88))
            mark.curve(
                to: point(32, 19.5),
                controlPoint1: point(21.75, 26.38),
                controlPoint2: point(26.38, 19.5)
            )
            mark.curve(
                to: point(42.25, 34.88),
                controlPoint1: point(37.63, 19.5),
                controlPoint2: point(42.25, 26.38)
            )
            mark.lineWidth = 4.8 * min(sx, sy)
            mark.lineCapStyle = .round
            mark.lineJoinStyle = .round
            NSColor.black.setStroke()
            mark.stroke()

            let dotSize: CGFloat = 10
            let dot = NSRect(
                x: rect.midX - dotSize * sx / 2,
                y: rect.midY - dotSize * sy / 2,
                width: dotSize * sx,
                height: dotSize * sy
            )
            NSColor.black.setFill()
            NSBezierPath(ovalIn: dot).fill()
            return true
        }
        image.isTemplate = true
        return image
    }
}
