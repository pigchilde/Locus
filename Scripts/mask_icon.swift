import AppKit
import Foundation

// Convert the approved raster artwork into native assets without redrawing its
// letterform. Saturation separates the purple ink from the neutral presentation
// background; every asset below uses that same extracted silhouette.
guard CommandLine.arguments.count == 5 else {
    fputs("Usage: mask_icon.swift <source.png> <app.png> <mark.png> <template.png>\n", stderr)
    exit(2)
}
let inputURL = URL(fileURLWithPath: CommandLine.arguments[1])
guard let source = NSBitmapImageRep(data: try Data(contentsOf: inputURL)) else {
    fatalError("Unable to read approved logo: \(inputURL.path)")
}

func bitmap(width: Int, height: Int, nonpremultiplied: Bool = false) -> NSBitmapImageRep {
    guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width,
        pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bitmapFormat: nonpremultiplied ? .alphaNonpremultiplied : [], bytesPerRow: 0, bitsPerPixel: 0) else { fatalError("Unable to allocate bitmap") }
    guard let tagged = rep.retagging(with: .sRGB) else { fatalError("Unable to tag sRGB bitmap") }
    return tagged
}
func save(_ rep: NSBitmapImageRep, to path: String) throws {
    guard let png = rep.representation(using: .png, properties: [:]) else {
        fatalError("Unable to encode PNG")
    }
    try png.write(to: URL(fileURLWithPath: path), options: .atomic)
}
func render(size: Int, draw: () -> Void) -> NSBitmapImageRep {
    let rep = bitmap(width: size, height: size)
    guard let context = NSGraphicsContext(bitmapImageRep: rep) else { fatalError("No graphics context") }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.shouldAntialias = true
    context.imageInterpolation = .high
    draw()
    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let ink = bitmap(width: source.pixelsWide, height: source.pixelsHigh, nonpremultiplied: true)
let template = bitmap(width: source.pixelsWide, height: source.pixelsHigh, nonpremultiplied: true)
var minX = source.pixelsWide, minY = source.pixelsHigh, maxX = 0, maxY = 0
guard source.bitsPerSample == 8, source.samplesPerPixel >= 3 else {
    fatalError("Expected 8-bit RGB PNG source")
}
var sourcePixel = [Int](repeating: 0, count: source.samplesPerPixel)
for y in 0..<source.pixelsHigh {
    for x in 0..<source.pixelsWide {
        source.getPixel(&sourcePixel, atX: x, y: y)
        let r = CGFloat(sourcePixel[0]) / 255
        let g = CGFloat(sourcePixel[1]) / 255
        let b = CGFloat(sourcePixel[2]) / 255
        let saturation = b - min(r, g)
        guard saturation > 0.025, b > r, r > g else { continue }
        let alpha = min(1, saturation / 0.68)
        // Undo the white matte at antialiased edges for clean transparent assets.
        func unmatte(_ value: CGFloat) -> CGFloat { min(1, max(0, (value - (1 - alpha)) / alpha)) }
        var inkPixel = [unmatte(r), unmatte(g), unmatte(b), alpha].map { Int(($0 * 255).rounded()) }
        ink.setPixel(&inkPixel, atX: x, y: y)
        var maskPixel = [0, 0, 0, Int((alpha * 255).rounded())]
        template.setPixel(&maskPixel, atX: x, y: y)
        minX = min(minX, x); maxX = max(maxX, x)
        minY = min(minY, y); maxY = max(maxY, y)
    }
}
guard minX < maxX, minY < maxY else { fatalError("No purple logo found in source") }
func image(_ rep: NSBitmapImageRep) -> NSImage {
    let result = NSImage(size: NSSize(width: rep.pixelsWide, height: rep.pixelsHigh))
    result.addRepresentation(rep)
    return result
}
let inkImage = image(ink)
let templateImage = image(template)
// NSImage source rectangles use a bottom-left origin.
let inkRect = NSRect(x: minX, y: source.pixelsHigh - maxY - 1,
    width: maxX - minX + 1, height: maxY - minY + 1)
func fitted(_ rect: NSRect, in bounds: NSRect) -> NSRect {
    let scale = min(bounds.width / rect.width, bounds.height / rect.height)
    let size = NSSize(width: rect.width * scale, height: rect.height * scale)
    return NSRect(x: bounds.midX - size.width / 2, y: bounds.midY - size.height / 2,
        width: size.width, height: size.height)
}

let app = render(size: 1024) {
    let plate = NSBezierPath(roundedRect: NSRect(x: 100, y: 100, width: 824, height: 824),
        xRadius: 184, yRadius: 184)
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.13)
    shadow.shadowBlurRadius = 22
    shadow.shadowOffset = NSSize(width: 0, height: -9)
    shadow.set()
    NSColor.white.setFill()
    plate.fill()
    NSGraphicsContext.restoreGraphicsState()
    // Preserve the selected image's original ink proportions and placement.
    inkImage.draw(in: NSRect(x: 0, y: 0, width: 1024, height: 1024),
        from: .zero, operation: .sourceOver, fraction: 1)
}
try save(app, to: CommandLine.arguments[2])
let mark = render(size: 512) {
    inkImage.draw(in: fitted(inkRect, in: NSRect(x: 24, y: 24, width: 464, height: 464)),
        from: inkRect, operation: .sourceOver, fraction: 1)
}
try save(mark, to: CommandLine.arguments[3])
let menuBar = render(size: 128) {
    templateImage.draw(in: fitted(inkRect, in: NSRect(x: 6, y: 6, width: 116, height: 116)),
        from: inkRect, operation: .sourceOver, fraction: 1)
}
try save(menuBar, to: CommandLine.arguments[4])
print("Prepared approved purple artwork: app icon, color mark, menu-bar template")
