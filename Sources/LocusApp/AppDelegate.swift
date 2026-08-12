import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var mainWindow: NSWindow?

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
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
        installStatusItem()
    }

    func registerMainWindow(_ window: NSWindow) {
        guard mainWindow !== window else { return }

        if let mainWindow {
            NotificationCenter.default.removeObserver(
                self,
                name: NSWindow.willCloseNotification,
                object: mainWindow
            )
        }

        mainWindow = window
        window.isReleasedWhenClosed = false
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(mainWindowWillClose),
            name: NSWindow.willCloseNotification,
            object: window
        )
    }

    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.autosaveName = "com.locusapp.Locus.statusItem"
        item.isVisible = true
        if let button = item.button {
            button.image = makeStatusBarIcon()
            button.imagePosition = .imageOnly
            button.toolTip = "Locus"
        }

        let menu = NSMenu()

        let showItem = NSMenuItem(
            title: "显示主界面",
            action: #selector(showMainWindow),
            keyEquivalent: ""
        )
        showItem.target = self
        showItem.image = NSImage(systemSymbolName: "macwindow", accessibilityDescription: nil)
        menu.addItem(showItem)

        let quitItem = NSMenuItem(
            title: "退出",
            action: #selector(quitApplication),
            keyEquivalent: "q"
        )
        quitItem.target = self
        quitItem.image = NSImage(systemSymbolName: "xmark.square", accessibilityDescription: nil)
        menu.addItem(quitItem)

        item.menu = menu
        statusItem = item
    }

    @objc private func showMainWindow() {
        NSApplication.shared.setActivationPolicy(.regular)
        let window = mainWindow ?? NSApplication.shared.windows.first(where: { $0.canBecomeMain })
        window?.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    @objc private func mainWindowWillClose(_ notification: Notification) {
        guard notification.object as? NSWindow === mainWindow else { return }
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    @objc private func quitApplication() {
        NSApplication.shared.terminate(nil)
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
