import AppKit
import Foundation

let assetDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: assetDirectory, withIntermediateDirectories: true)

func color(_ hex: UInt32, alpha: CGFloat = 1) -> NSColor {
    NSColor(
        calibratedRed: CGFloat((hex >> 16) & 0xff) / 255,
        green: CGFloat((hex >> 8) & 0xff) / 255,
        blue: CGFloat(hex & 0xff) / 255,
        alpha: alpha
    )
}

func roundedRect(_ rect: NSRect, radius: CGFloat, fill: NSColor) {
    fill.setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}

func text(_ value: String, x: CGFloat, y: CGFloat, size: CGFloat, weight: NSFont.Weight, fill: NSColor) {
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: fill
    ]
    (value as NSString).draw(at: NSPoint(x: x, y: y), withAttributes: attributes)
}

func png(width: Int, height: Int, draw: () -> Void) -> NSBitmapImageRep {
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: width,
        pixelsHigh: height,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    let context = NSGraphicsContext(bitmapImageRep: bitmap)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high
    draw()
    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
    return bitmap
}

func save(_ bitmap: NSBitmapImageRep, as name: String) throws {
    let data = bitmap.representation(using: .png, properties: [:])!
    try data.write(to: assetDirectory.appendingPathComponent(name), options: .atomic)
}

func drawIcon() {
    let canvas = NSRect(x: 0, y: 0, width: 1024, height: 1024)
    let background = NSBezierPath(roundedRect: canvas.insetBy(dx: 22, dy: 22), xRadius: 220, yRadius: 220)
    NSGradient(colors: [color(0x172347), color(0x245b7a), color(0x24a5a6)])?.draw(in: background, angle: 48)

    let glow = NSBezierPath(ovalIn: NSRect(x: 510, y: 520, width: 470, height: 470))
    color(0x8be9df, alpha: 0.08).setFill()
    glow.fill()

    let frame = NSBezierPath(roundedRect: NSRect(x: 176, y: 278, width: 672, height: 468), xRadius: 78, yRadius: 78)
    color(0x0b1831, alpha: 0.62).setFill()
    frame.fill()
    color(0xf3fbff).setStroke()
    frame.lineWidth = 24
    frame.stroke()

    for y in [336.0, 449.0, 562.0, 675.0] {
        roundedRect(NSRect(x: 207, y: y, width: 30, height: 48), radius: 12, fill: color(0xa7f3ec))
        roundedRect(NSRect(x: 787, y: y, width: 30, height: 48), radius: 12, fill: color(0xa7f3ec))
    }

    let baseline: CGFloat = 513
    let bars: [(CGFloat, CGFloat)] = [
        (300, 54), (342, 96), (384, 144), (426, 72), (468, 112),
        (554, 118), (596, 76), (638, 148), (680, 94), (722, 56)
    ]
    for (x, height) in bars {
        roundedRect(NSRect(x: x, y: baseline - height / 2, width: 21, height: height), radius: 10, fill: color(0x95eee5))
    }

    let cut = NSBezierPath()
    cut.move(to: NSPoint(x: 512, y: 364))
    cut.line(to: NSPoint(x: 512, y: 662))
    color(0xffc66d).setStroke()
    cut.lineWidth = 20
    cut.lineCapStyle = .round
    cut.stroke()

    let marker = NSBezierPath(ovalIn: NSRect(x: 478, y: 648, width: 68, height: 68))
    color(0xffc66d).setFill()
    marker.fill()
    let markerCenter = NSBezierPath()
    markerCenter.move(to: NSPoint(x: 499, y: 682))
    markerCenter.line(to: NSPoint(x: 525, y: 682))
    color(0x172347).setStroke()
    markerCenter.lineWidth = 10
    markerCenter.lineCapStyle = .round
    markerCenter.stroke()
}

func drawLandscape(in rect: NSRect) {
    let sky = NSBezierPath(roundedRect: rect, xRadius: 24, yRadius: 24)
    NSGradient(colors: [color(0x192b50), color(0x467e99), color(0x9bd3cc)])?.draw(in: sky, angle: 90)

    let distant = NSBezierPath()
    distant.move(to: NSPoint(x: rect.minX, y: rect.minY + rect.height * 0.34))
    distant.line(to: NSPoint(x: rect.minX + rect.width * 0.24, y: rect.minY + rect.height * 0.78))
    distant.line(to: NSPoint(x: rect.minX + rect.width * 0.42, y: rect.minY + rect.height * 0.44))
    distant.line(to: NSPoint(x: rect.minX + rect.width * 0.60, y: rect.minY + rect.height * 0.84))
    distant.line(to: NSPoint(x: rect.maxX, y: rect.minY + rect.height * 0.30))
    distant.line(to: NSPoint(x: rect.maxX, y: rect.minY))
    distant.line(to: NSPoint(x: rect.minX, y: rect.minY))
    distant.close()
    color(0x38577a).setFill()
    distant.fill()

    let near = NSBezierPath()
    near.move(to: NSPoint(x: rect.minX, y: rect.minY + rect.height * 0.22))
    near.line(to: NSPoint(x: rect.minX + rect.width * 0.28, y: rect.minY + rect.height * 0.62))
    near.line(to: NSPoint(x: rect.minX + rect.width * 0.48, y: rect.minY + rect.height * 0.20))
    near.line(to: NSPoint(x: rect.minX + rect.width * 0.72, y: rect.minY + rect.height * 0.55))
    near.line(to: NSPoint(x: rect.maxX, y: rect.minY + rect.height * 0.16))
    near.line(to: NSPoint(x: rect.maxX, y: rect.minY))
    near.line(to: NSPoint(x: rect.minX, y: rect.minY))
    near.close()
    color(0x223e58).setFill()
    near.fill()

    let road = NSBezierPath()
    road.move(to: NSPoint(x: rect.minX + rect.width * 0.08, y: rect.minY + rect.height * 0.08))
    road.curve(to: NSPoint(x: rect.minX + rect.width * 0.56, y: rect.minY + rect.height * 0.22), controlPoint1: NSPoint(x: rect.minX + rect.width * 0.29, y: rect.minY + rect.height * 0.14), controlPoint2: NSPoint(x: rect.minX + rect.width * 0.42, y: rect.minY + rect.height * 0.08))
    road.curve(to: NSPoint(x: rect.minX + rect.width * 0.82, y: rect.minY + rect.height * 0.34), controlPoint1: NSPoint(x: rect.minX + rect.width * 0.66, y: rect.minY + rect.height * 0.38), controlPoint2: NSPoint(x: rect.minX + rect.width * 0.71, y: rect.minY + rect.height * 0.26))
    color(0xe9e5d6).setStroke()
    road.lineWidth = 18
    road.lineCapStyle = .round
    road.stroke()

    let truckBody = NSBezierPath(roundedRect: NSRect(x: rect.minX + rect.width * 0.55, y: rect.minY + rect.height * 0.24, width: rect.width * 0.18, height: rect.height * 0.12), xRadius: 9, yRadius: 9)
    color(0x3cd0c4).setFill()
    truckBody.fill()
    let cab = NSBezierPath(roundedRect: NSRect(x: rect.minX + rect.width * 0.73, y: rect.minY + rect.height * 0.24, width: rect.width * 0.09, height: rect.height * 0.10), xRadius: 8, yRadius: 8)
    color(0xffbf69).setFill()
    cab.fill()
    for x in [rect.minX + rect.width * 0.59, rect.minX + rect.width * 0.75] {
        let wheel = NSBezierPath(ovalIn: NSRect(x: x, y: rect.minY + rect.height * 0.19, width: 22, height: 22))
        color(0x12233f).setFill()
        wheel.fill()
        color(0xdbe9ee).setStroke()
        wheel.lineWidth = 4
        wheel.stroke()
    }
}

let icon = png(width: 1024, height: 1024, draw: drawIcon)
try save(icon, as: "app-icon.png")

let banner = png(width: 1280, height: 640) {
    let canvas = NSRect(x: 0, y: 0, width: 1280, height: 640)
    NSGradient(colors: [color(0x111a32), color(0x1c3153), color(0x17495b)])?.draw(in: canvas, angle: 0)

    for index in 0..<24 {
        let x = CGFloat((index * 173 + 81) % 1280)
        let y = CGFloat((index * 97 + 41) % 640)
        let star = NSBezierPath(ovalIn: NSRect(x: x, y: y, width: 3, height: 3))
        color(0xd4f8f5, alpha: 0.18).setFill()
        star.fill()
    }

    let badge = NSBezierPath(roundedRect: NSRect(x: 72, y: 515, width: 236, height: 42), xRadius: 21, yRadius: 21)
    color(0x74e1d4, alpha: 0.14).setFill()
    badge.fill()
    text("TIGHTTAKE", x: 91, y: 528, size: 16, weight: .bold, fill: color(0xaff5ed))
    text("Clean cuts,", x: 72, y: 414, size: 68, weight: .bold, fill: color(0xf7fbff))
    text("made locally.", x: 72, y: 337, size: 68, weight: .bold, fill: color(0xf7fbff))
    text("A menu-bar silence cutter for macOS.", x: 76, y: 279, size: 24, weight: .regular, fill: color(0xc4d5e6))
    text("MLX Whisper  ·  FFmpeg  ·  Apple silicon", x: 76, y: 226, size: 18, weight: .medium, fill: color(0x82dcd4))

    let panelRect = NSRect(x: 692, y: 55, width: 526, height: 530)
    let panel = NSBezierPath(roundedRect: panelRect, xRadius: 30, yRadius: 30)
    color(0x0c172b, alpha: 0.72).setFill()
    panel.fill()
    color(0xd4ecf1, alpha: 0.20).setStroke()
    panel.lineWidth = 2
    panel.stroke()

    let screen = NSRect(x: 718, y: 246, width: 474, height: 308)
    drawLandscape(in: screen)

    roundedRect(NSRect(x: 740, y: 475, width: 88, height: 32), radius: 16, fill: color(0x0d2039, alpha: 0.70))
    text("PREVIEW", x: 756, y: 485, size: 12, weight: .bold, fill: color(0xe6f5f4))

    roundedRect(NSRect(x: 718, y: 82, width: 474, height: 135), radius: 20, fill: color(0x182943))
    text("SPEECH TIMELINE", x: 740, y: 183, size: 12, weight: .bold, fill: color(0x96b0c6))
    let heights: [CGFloat] = [20, 34, 51, 30, 45, 60, 29, 38, 48, 24, 0, 0, 0, 31, 48, 60, 35, 47, 26, 54, 34, 24, 43, 32]
    for (index, height) in heights.enumerated() where height > 0 {
        let x = 741 + CGFloat(index) * 17
        let bar = NSBezierPath(roundedRect: NSRect(x: x, y: 126 - height / 2, width: 9, height: height), xRadius: 4, yRadius: 4)
        (index == 10 || index == 13 ? color(0xffc36b) : color(0x62d8cd)).setFill()
        bar.fill()
    }
    let cutLine = NSBezierPath()
    cutLine.move(to: NSPoint(x: 920, y: 106))
    cutLine.line(to: NSPoint(x: 920, y: 160))
    color(0xffc36b).setStroke()
    cutLine.lineWidth = 3
    cutLine.stroke()
}
try save(banner, as: "repository-banner.png")
