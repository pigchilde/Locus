import AppKit
import SwiftUI

/// The approved artwork is shared by the app, menu bar, and in-app branding.
/// Bundled PNGs are copied by build_app.sh; fallback symbols keep swift run usable.
enum LocusBrand {
    private static func image(named name: String) -> NSImage? {
        Bundle.main.url(forResource: name, withExtension: "png")
            .flatMap { NSImage(contentsOf: $0) }
    }

    static let appIcon = image(named: "LocusDockIcon")
        ?? NSImage(named: NSImage.applicationIconName)
        ?? NSImage(size: NSSize(width: 1024, height: 1024))

    static let mark = image(named: "LocusMark") ?? appIcon

    static let menuBarIcon: NSImage = {
        let icon = image(named: "LocusMenuBarTemplate")
            ?? NSImage(systemSymbolName: "waveform", accessibilityDescription: "Locus")
            ?? NSImage(size: NSSize(width: 18, height: 18))
        icon.isTemplate = true
        return icon
    }()
}

struct LocusMark: View {
    var body: some View {
        Image(nsImage: LocusBrand.mark)
            .resizable()
            .scaledToFit()
            .accessibilityLabel("Locus")
    }
}

struct LocusAppIcon: View {
    var size: CGFloat = 42

    var body: some View {
        Image(nsImage: LocusBrand.appIcon)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityLabel("Locus")
    }
}
