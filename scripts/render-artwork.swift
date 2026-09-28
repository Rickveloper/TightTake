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

func drawWaveform(in rect: NSRect, levels: [CGFloat], barWidth: CGFloat, fill: NSColor) {
    guard !levels.isEmpty else { return }
    let gap = max(2, (rect.width - CGFloat(levels.count) * barWidth) / CGFloat(levels.count - 1))
    let centerY = rect.midY
    for (index, level) in levels.enumerated() {
        let height = max(8, rect.height * level)
        let x = rect.minX + CGFloat(index) * (barWidth + gap)
        roundedRect(NSRect(x: x, y: centerY - height / 2, width: barWidth, height: height), radius: barWidth / 2, fill: fill)
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
    text("Cut the pauses.", x: 72, y: 414, size: 63, weight: .bold, fill: color(0xf7fbff))
    text("Keep the words.", x: 72, y: 340, size: 63, weight: .bold, fill: color(0xf7fbff))
    text("Speech-aware silence trimming for macOS.", x: 76, y: 281, size: 22, weight: .regular, fill: color(0xc4d5e6))
    text("MLX Whisper  ·  FFmpeg  ·  Apple silicon", x: 76, y: 230, size: 18, weight: .medium, fill: color(0x82dcd4))
    text("Illustrative workflow · sample timings · original preserved", x: 76, y: 186, size: 14, weight: .regular, fill: color(0xa9bdc9))

    let panelRect = NSRect(x: 650, y: 42, width: 576, height: 552)
    let panel = NSBezierPath(roundedRect: panelRect, xRadius: 25, yRadius: 25)
    color(0x0c172b, alpha: 0.82).setFill()
    panel.fill()
    color(0xd4ecf1, alpha: 0.24).setStroke()
    panel.lineWidth = 2
    panel.stroke()

    text("VIDEO SMART CUT", x: 680, y: 554, size: 15, weight: .bold, fill: color(0xf0f6f3))
    text("TIGHTTAKE", x: 680, y: 537, size: 10, weight: .medium, fill: color(0x91afb9))
    roundedRect(NSRect(x: 1084, y: 540, width: 111, height: 28), radius: 14, fill: color(0x1c453f))
    let localDot = NSBezierPath(ovalIn: NSRect(x: 1097, y: 550, width: 8, height: 8))
    color(0x7ee1b6).setFill()
    localDot.fill()
    text("ON THIS MAC", x: 1112, y: 550, size: 9, weight: .bold, fill: color(0xb5e7d7))

    roundedRect(NSRect(x: 678, y: 474, width: 520, height: 52), radius: 11, fill: color(0x192d39))
    roundedRect(NSRect(x: 692, y: 486, width: 28, height: 28), radius: 7, fill: color(0x2a4a58))
    text("▶", x: 700, y: 494, size: 11, weight: .bold, fill: color(0x65d5c8))
    text("Interview_take_04.mov", x: 731, y: 499, size: 13, weight: .semibold, fill: color(0xf0f6f3))
    text("SELECTED VIDEO  ·  SOURCE LEFT UNCHANGED", x: 731, y: 483, size: 9, weight: .medium, fill: color(0x91a8b2))
    roundedRect(NSRect(x: 1164, y: 492, width: 20, height: 20), radius: 10, fill: color(0x214b43))
    text("✓", x: 1170, y: 496, size: 10, weight: .bold, fill: color(0x8de4be))

    roundedRect(NSRect(x: 678, y: 314, width: 520, height: 146), radius: 12, fill: color(0x101f2a))
    text("BEFORE  ·  SOURCE VIDEO", x: 699, y: 437, size: 11, weight: .bold, fill: color(0xaac1c9))
    text("06:42", x: 1125, y: 437, size: 12, weight: .bold, fill: color(0xe8f3ef))
    roundedRect(NSRect(x: 697, y: 346, width: 482, height: 72), radius: 8, fill: color(0x0b1720))
    roundedRect(NSRect(x: 708, y: 357, width: 120, height: 50), radius: 5, fill: color(0x163b3b))
    roundedRect(NSRect(x: 832, y: 357, width: 42, height: 50), radius: 5, fill: color(0x44351f))
    roundedRect(NSRect(x: 878, y: 357, width: 135, height: 50), radius: 5, fill: color(0x163b3b))
    roundedRect(NSRect(x: 1017, y: 357, width: 38, height: 50), radius: 5, fill: color(0x44351f))
    roundedRect(NSRect(x: 1059, y: 357, width: 108, height: 50), radius: 5, fill: color(0x163b3b))
    drawWaveform(in: NSRect(x: 716, y: 363, width: 104, height: 38), levels: [0.32, 0.75, 0.52, 0.9, 0.42, 0.72, 1.0, 0.56, 0.34], barWidth: 5, fill: color(0x65d5c8))
    drawWaveform(in: NSRect(x: 886, y: 363, width: 119, height: 38), levels: [0.38, 0.62, 0.96, 0.52, 0.79, 0.34, 0.7, 1.0, 0.58, 0.82], barWidth: 5, fill: color(0x65d5c8))
    drawWaveform(in: NSRect(x: 1067, y: 363, width: 91, height: 38), levels: [0.42, 0.88, 0.6, 1.0, 0.52, 0.76, 0.36], barWidth: 5, fill: color(0x65d5c8))
    text("1:42", x: 837, y: 377, size: 9, weight: .bold, fill: color(0xffd17d))
    text("0:56", x: 1021, y: 377, size: 9, weight: .bold, fill: color(0xffd17d))
    text("TEAL = SPEECH KEPT     AMBER = LONG PAUSE REMOVED", x: 699, y: 326, size: 9, weight: .medium, fill: color(0x91a8b2))

    text("LOCAL SPEECH MAP", x: 699, y: 294, size: 9, weight: .bold, fill: color(0x78d9ce))
    let transition = NSBezierPath()
    transition.move(to: NSPoint(x: 828, y: 297))
    transition.line(to: NSPoint(x: 1170, y: 297))
    color(0x52707a).setStroke()
    transition.lineWidth = 1
    transition.stroke()

    roundedRect(NSRect(x: 678, y: 158, width: 520, height: 126), radius: 12, fill: color(0x10221f))
    text("AFTER  ·  NEW MP4", x: 699, y: 259, size: 11, weight: .bold, fill: color(0xb8e8d4))
    text("04:04  ·  2 PAUSES CUT", x: 1038, y: 259, size: 10, weight: .bold, fill: color(0x8de4be))
    roundedRect(NSRect(x: 697, y: 184, width: 482, height: 58), radius: 8, fill: color(0x0b1b18))
    roundedRect(NSRect(x: 708, y: 193, width: 146, height: 40), radius: 5, fill: color(0x16463f))
    roundedRect(NSRect(x: 858, y: 193, width: 4, height: 40), radius: 2, fill: color(0xa1cfc0, alpha: 0.62))
    roundedRect(NSRect(x: 866, y: 193, width: 146, height: 40), radius: 5, fill: color(0x16463f))
    roundedRect(NSRect(x: 1016, y: 193, width: 4, height: 40), radius: 2, fill: color(0xa1cfc0, alpha: 0.62))
    roundedRect(NSRect(x: 1024, y: 193, width: 143, height: 40), radius: 5, fill: color(0x16463f))
    drawWaveform(in: NSRect(x: 715, y: 197, width: 131, height: 32), levels: [0.34, 0.72, 0.46, 0.92, 0.54, 0.78, 1.0, 0.52, 0.86, 0.38, 0.68], barWidth: 5, fill: color(0x7ee1b6))
    drawWaveform(in: NSRect(x: 873, y: 197, width: 132, height: 32), levels: [0.44, 0.84, 0.55, 1.0, 0.42, 0.68, 0.92, 0.48, 0.78, 0.34, 0.64], barWidth: 5, fill: color(0x7ee1b6))
    drawWaveform(in: NSRect(x: 1031, y: 197, width: 128, height: 32), levels: [0.38, 0.8, 0.56, 0.94, 0.46, 0.74, 1.0, 0.56, 0.82, 0.34, 0.62], barWidth: 5, fill: color(0x7ee1b6))

    roundedRect(NSRect(x: 678, y: 82, width: 520, height: 57), radius: 10, fill: color(0x192d39))
    roundedRect(NSRect(x: 692, y: 99, width: 22, height: 22), radius: 11, fill: color(0x214b43))
    text("✓", x: 699, y: 105, size: 10, weight: .bold, fill: color(0x8de4be))
    text("Interview_take_04_TightTake.mp4", x: 724, y: 109, size: 12, weight: .semibold, fill: color(0xf0f6f3))
    text("NEW FILE  ·  ORIGINAL VIDEO PRESERVED", x: 724, y: 92, size: 9, weight: .medium, fill: color(0x91a8b2))
    text("MP4", x: 1155, y: 105, size: 10, weight: .bold, fill: color(0x9fc2c5))
}
try save(banner, as: "repository-banner.png")
