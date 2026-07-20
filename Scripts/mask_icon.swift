import AppKit
import Foundation

guard CommandLine.arguments.count == 3 else {
    fputs("Usage: mask_icon.swift <input.png> <output.png>\n", stderr)
    exit(2)
}

let inputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])

guard let source = NSImage(contentsOf: inputURL) else {
    fputs("Unable to read icon source: \(inputURL.path)\n", stderr)
    exit(1)
}

let canvasSize = 1024
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: canvasSize,
    pixelsHigh: canvasSize,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fputs("Unable to allocate icon bitmap\n", stderr)
    exit(1)
}

guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fputs("Unable to create icon graphics context\n", stderr)
    exit(1)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
context.shouldAntialias = true
context.imageInterpolation = .high

let canvas = NSRect(x: 0, y: 0, width: canvasSize, height: canvasSize)
NSColor.clear.setFill()
canvas.fill()

let iconBounds = NSRect(x: 0, y: 0, width: 1024, height: 1024)
NSBezierPath(roundedRect: iconBounds, xRadius: 224, yRadius: 224).addClip()
source.draw(in: canvas, from: .zero, operation: .copy, fraction: 1)

context.flushGraphics()
NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Unable to encode masked icon\n", stderr)
    exit(1)
}

try png.write(to: outputURL, options: .atomic)
