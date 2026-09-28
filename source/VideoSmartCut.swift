import Cocoa

struct WhisperJSON {
    let segments: [Segment]

    struct Segment: Decodable {
        let words: [Word]?
    }

    struct Word: Decodable {
        let start: Double
        let end: Double
        let word: String?
    }

    static func decode(from data: Data) throws -> WhisperJSON {
        let document: Any
        do {
            document = try JSONSerialization.jsonObject(with: data, options: [.json5Allowed])
        } catch {
            throw NSError(domain: "VideoSmartCut", code: 4, userInfo: [NSLocalizedDescriptionKey: "Whisper produced an unreadable transcript: \(String(reflecting: error))"])
        }

        guard let result = document as? [String: Any],
              let rawSegments = result["segments"] as? [[String: Any]] else {
            throw NSError(domain: "VideoSmartCut", code: 5, userInfo: [NSLocalizedDescriptionKey: "Whisper's transcript is missing the expected segments list."])
        }

        let segments = rawSegments.map { rawSegment -> Segment in
            let rawWords = rawSegment["words"] as? [[String: Any]] ?? []
            let words = rawWords.compactMap { rawWord -> Word? in
                guard let start = (rawWord["start"] as? NSNumber)?.doubleValue,
                      let end = (rawWord["end"] as? NSNumber)?.doubleValue,
                      start.isFinite,
                      end.isFinite else { return nil }
                return Word(start: start, end: end, word: rawWord["word"] as? String)
            }
            return Segment(words: words)
        }
        return WhisperJSON(segments: segments)
    }
}

final class CardView: NSView {
    init(content: NSView) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 16
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.55).cgColor
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            content.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            content.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            content.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class DropView: NSView {
    var onFile: ((URL) -> Void)?
    private let allowedExtensions: Set<String> = ["mp4", "mov", "m4v", "mkv"]
    private let iconView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "Drop a video here")
    private let detailLabel = NSTextField(labelWithString: "Drag in a video or choose a file · MP4, MOV, M4V, MKV")
    private var isDragTargeted = false
    private var selectedURL: URL?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 14
        layer?.borderWidth = 1.5
        layer?.borderColor = NSColor.controlAccentColor.withAlphaComponent(0.6).cgColor
        layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.55).cgColor
        registerForDraggedTypes([.fileURL])

        iconView.image = NSImage(systemSymbolName: "arrow.down.doc", accessibilityDescription: "Drop a video")
        iconView.contentTintColor = .controlAccentColor
        iconView.setContentHuggingPriority(.required, for: .horizontal)

        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .labelColor
        detailLabel.font = .systemFont(ofSize: 13)
        detailLabel.textColor = .secondaryLabelColor
        detailLabel.lineBreakMode = .byTruncatingTail

        let textStack = NSStackView(views: [titleLabel, detailLabel])
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 5

        let contentStack = NSStackView(views: [iconView, textStack])
        contentStack.orientation = .horizontal
        contentStack.alignment = .centerY
        contentStack.spacing = 14
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),
            contentStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            contentStack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20)
        ])
        setAccessibilityElement(true)
        setAccessibilityRole(.group)
        setAccessibilityLabel("Video drop area")
        setAccessibilityHelp("Drop an MP4, MOV, M4V, or MKV video here, or use Choose Video.")
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard let url = videoURL(from: sender), allowedExtensions.contains(url.pathExtension.lowercased()) else { return [] }
        isDragTargeted = true
        updateDropAppearance()
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        isDragTargeted = false
        updateDropAppearance()
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let url = videoURL(from: sender), allowedExtensions.contains(url.pathExtension.lowercased()) else {
            isDragTargeted = false
            updateDropAppearance()
            return false
        }
        isDragTargeted = false
        updateDropAppearance()
        onFile?(url)
        return true
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        isDragTargeted = false
        updateDropAppearance()
    }

    func setSelectedVideo(_ url: URL?) {
        selectedURL = url
        isDragTargeted = false
        updateDropAppearance()
        if let selectedURL {
            setAccessibilityValue(selectedURL.path as NSString)
        } else {
            setAccessibilityValue("No video selected" as NSString)
        }
    }

    private func videoURL(from sender: NSDraggingInfo) -> URL? {
        (sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL])?.first
    }

    private func updateDropAppearance() {
        layer?.borderWidth = isDragTargeted ? 2.5 : 1.5
        layer?.borderColor = isDragTargeted
            ? NSColor.controlAccentColor.cgColor
            : NSColor.controlAccentColor.withAlphaComponent(0.6).cgColor
        layer?.backgroundColor = isDragTargeted
            ? NSColor.controlAccentColor.withAlphaComponent(0.12).cgColor
            : NSColor.controlBackgroundColor.withAlphaComponent(0.55).cgColor
        if isDragTargeted {
            titleLabel.stringValue = "Release to add this video"
            detailLabel.stringValue = "The current selection will be replaced"
        } else if let selectedURL {
            titleLabel.stringValue = selectedURL.lastPathComponent
            detailLabel.stringValue = "Ready to edit · drag another video here to replace it"
        } else {
            titleLabel.stringValue = "Drop a video here"
            detailLabel.stringValue = "Drag in a video or choose a file · MP4, MOV, M4V, MKV"
        }
    }
}

final class WhisperProgressParser {
    private var pending = ""

    func append(_ chunk: String) -> [Double] {
        pending.append(contentsOf: chunk)
        var values: [Double] = []
        let separators = CharacterSet(charactersIn: "\r\n")
        while let range = pending.rangeOfCharacter(from: separators) {
            let line = String(pending[..<range.lowerBound])
            pending.removeSubrange(..<range.upperBound)
            if let percent = Self.percent(in: line) { values.append(percent / 100) }
        }
        return values
    }

    private static func percent(in line: String) -> Double? {
        guard let mark = line.firstIndex(of: "%") else { return nil }
        let digits = line[..<mark].reversed().prefix(while: { $0.isNumber }).reversed()
        guard let value = Double(String(digits)), (0...100).contains(value) else { return nil }
        return value
    }
}

final class FFmpegProgressParser {
    private var pending = ""
    private let duration: Double

    init(duration: Double) {
        self.duration = duration
    }

    func append(_ chunk: String) -> [Double] {
        pending.append(contentsOf: chunk)
        var values: [Double] = []
        let separators = CharacterSet(charactersIn: "\r\n")
        while let range = pending.rangeOfCharacter(from: separators) {
            let line = String(pending[..<range.lowerBound])
            pending.removeSubrange(..<range.upperBound)
            guard line.hasPrefix("out_time_us="),
                  let microseconds = Double(line.dropFirst("out_time_us=".count)),
                  duration > 0,
                  microseconds >= 0 else { continue }
            values.append(min(1, microseconds / 1_000_000 / duration))
        }
        return values
    }
}

final class ProcessOutputBuffer {
    private let lock = NSLock()
    private var data = Data()

    func append(_ chunk: Data) {
        lock.lock()
        data.append(chunk)
        lock.unlock()
    }

    func value() -> Data {
        lock.lock()
        defer { lock.unlock() }
        return data
    }
}

final class ProcessingAnimationView: NSView {
    private struct Curve {
        let start: CGPoint
        let control1: CGPoint
        let control2: CGPoint
        let end: CGPoint

        func point(at progress: CGFloat) -> CGPoint {
            let inverse = 1 - progress
            let a = inverse * inverse * inverse
            let b = 3 * inverse * inverse * progress
            let c = 3 * inverse * progress * progress
            let d = progress * progress * progress
            return CGPoint(
                x: a * start.x + b * control1.x + c * control2.x + d * end.x,
                y: a * start.y + b * control1.y + c * control2.y + d * end.y
            )
        }

        func tangent(at progress: CGFloat) -> CGPoint {
            let inverse = 1 - progress
            return CGPoint(
                x: 3 * inverse * inverse * (control1.x - start.x)
                    + 6 * inverse * progress * (control2.x - control1.x)
                    + 3 * progress * progress * (end.x - control2.x),
                y: 3 * inverse * inverse * (control1.y - start.y)
                    + 6 * inverse * progress * (control2.y - control1.y)
                    + 3 * progress * progress * (end.y - control2.y)
            )
        }
    }

    private var animationTimer: Timer?
    private var animationPhase: CGFloat = 0

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 14
        layer?.masksToBounds = true
        setAccessibilityLabel("Mountain truck animation")
        setAccessibilityHelp("A little truck drives over a mountain while your video is being processed.")
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ dirtyRect: NSRect) {
        guard bounds.width > 0, bounds.height > 0 else { return }
        let width = bounds.width
        let height = bounds.height
        let point = { (x: CGFloat, y: CGFloat) in CGPoint(x: x * width, y: y * height) }

        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(roundedRect: bounds, xRadius: 14, yRadius: 14).addClip()
        NSGradient(colors: [
            NSColor(calibratedRed: 0.10, green: 0.17, blue: 0.30, alpha: 1),
            NSColor(calibratedRed: 0.28, green: 0.45, blue: 0.57, alpha: 1)
        ])?.draw(in: bounds, angle: 90)

        drawSun(at: point(0.84, 0.76), phase: animationPhase)
        let cloudDrift = CGFloat(sin(Double(animationPhase) * 2 * Double.pi)) * 8
        drawCloud(at: CGPoint(x: width * 0.16 + cloudDrift, y: height * 0.73), scale: 0.72)
        drawCloud(at: CGPoint(x: width * 0.44 - cloudDrift * 0.6, y: height * 0.84), scale: 0.52)

        fillPolygon([
            point(0, 0.30), point(0.15, 0.70), point(0.28, 0.43),
            point(0.42, 0.76), point(0.57, 0.39), point(0.75, 0.67),
            point(0.88, 0.38), point(1, 0.61), point(1, 0), point(0, 0)
        ], color: NSColor(calibratedRed: 0.34, green: 0.48, blue: 0.57, alpha: 0.8))
        fillPolygon([
            point(0, 0.12), point(0.17, 0.32), point(0.32, 0.25),
            point(0.54, 0.92), point(0.69, 0.35), point(0.84, 0.26),
            point(1, 0.18), point(1, 0), point(0, 0)
        ], color: NSColor(calibratedRed: 0.11, green: 0.27, blue: 0.34, alpha: 1))
        fillPolygon([
            point(0.44, 0.61), point(0.54, 0.92), point(0.64, 0.60),
            point(0.59, 0.65), point(0.56, 0.61), point(0.53, 0.70),
            point(0.50, 0.65), point(0.47, 0.68)
        ], color: NSColor(calibratedRed: 0.88, green: 0.94, blue: 0.94, alpha: 0.95))
        fillPolygon([
            point(0.54, 0.92), point(0.69, 0.35), point(0.60, 0.49),
            point(0.64, 0.34), point(0.74, 0.28), point(0.82, 0.24),
            point(0.91, 0.16), point(1, 0.12), point(1, 0), point(0.40, 0)
        ], color: NSColor(calibratedRed: 0.08, green: 0.22, blue: 0.28, alpha: 0.74))

        drawPine(at: point(0.04, 0.08), scale: 0.9)
        drawPine(at: point(0.10, 0.10), scale: 0.65)
        drawPine(at: point(0.94, 0.08), scale: 0.78)
        drawPine(at: point(0.98, 0.08), scale: 0.55)

        let curves = routeCurves(width: width, height: height)
        let road = NSBezierPath()
        road.move(to: curves[0].start)
        for curve in curves {
            road.curve(to: curve.end, controlPoint1: curve.control1, controlPoint2: curve.control2)
        }
        stroke(road, color: NSColor(calibratedRed: 0.06, green: 0.13, blue: 0.17, alpha: 0.72), width: 15)
        stroke(road, color: NSColor(calibratedRed: 0.58, green: 0.65, blue: 0.62, alpha: 1), width: 10)
        road.lineWidth = 1.2
        road.lineCapStyle = .round
        road.setLineDash([3, 4], count: 2, phase: 0)
        NSColor(calibratedRed: 0.96, green: 0.83, blue: 0.55, alpha: 0.9).setStroke()
        road.stroke()

        drawTruck(curves: curves, phase: animationPhase)
        drawSceneLabels(width: width, height: height)
        NSGraphicsContext.restoreGraphicsState()

        let border = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: 14, yRadius: 14)
        border.lineWidth = 1
        NSColor.white.withAlphaComponent(0.18).setStroke()
        border.stroke()
    }

    func startAnimating() {
        guard animationTimer == nil else { return }
        animationTimer = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.animationPhase = (self.animationPhase + 1.0 / 540.0).truncatingRemainder(dividingBy: 1)
            self.needsDisplay = true
        }
        if let animationTimer {
            RunLoop.main.add(animationTimer, forMode: .common)
        }
    }

    func stopAnimating() {
        animationTimer?.invalidate()
        animationTimer = nil
        animationPhase = 0
        needsDisplay = true
    }

    private func routeCurves(width: CGFloat, height: CGFloat) -> [Curve] {
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * width, y: y * height) }
        return [
            Curve(start: point(0.01, 0.16), control1: point(0.13, 0.16), control2: point(0.14, 0.43), end: point(0.34, 0.43)),
            Curve(start: point(0.34, 0.43), control1: point(0.43, 0.43), control2: point(0.45, 0.76), end: point(0.56, 0.73)),
            Curve(start: point(0.56, 0.73), control1: point(0.69, 0.71), control2: point(0.71, 0.43), end: point(0.83, 0.43)),
            Curve(start: point(0.83, 0.43), control1: point(0.91, 0.43), control2: point(0.92, 0.19), end: point(0.99, 0.17))
        ]
    }

    private func drawSun(at center: CGPoint, phase: CGFloat) {
        let halo = NSBezierPath(ovalIn: CGRect(x: center.x - 19, y: center.y - 19, width: 38, height: 38))
        NSColor(calibratedRed: 1, green: 0.83, blue: 0.52, alpha: 0.12).setFill()
        halo.fill()
        let sun = NSBezierPath(ovalIn: CGRect(x: center.x - 8, y: center.y - 8, width: 16, height: 16))
        NSColor(calibratedRed: 1, green: 0.83, blue: 0.52, alpha: 0.95).setFill()
        sun.fill()
        let rays = NSBezierPath()
        for index in 0..<8 {
            let angle = Double(index) * Double.pi / 4 + Double(phase) * Double.pi / 5
            let inner = CGFloat(11)
            let outer = CGFloat(index.isMultiple(of: 2) ? 15 : 13)
            rays.move(to: CGPoint(x: center.x + cos(angle) * inner, y: center.y + sin(angle) * inner))
            rays.line(to: CGPoint(x: center.x + cos(angle) * outer, y: center.y + sin(angle) * outer))
        }
        rays.lineWidth = 1.2
        rays.lineCapStyle = .round
        NSColor(calibratedRed: 1, green: 0.83, blue: 0.52, alpha: 0.7).setStroke()
        rays.stroke()
    }

    private func drawCloud(at center: CGPoint, scale: CGFloat) {
        let color = NSColor.white.withAlphaComponent(0.48)
        let parts = [
            CGRect(x: center.x - 17 * scale, y: center.y - 3 * scale, width: 20 * scale, height: 9 * scale),
            CGRect(x: center.x - 9 * scale, y: center.y, width: 14 * scale, height: 13 * scale),
            CGRect(x: center.x, y: center.y - 2 * scale, width: 21 * scale, height: 10 * scale)
        ]
        for rect in parts {
            let cloudPart = NSBezierPath(ovalIn: rect)
            color.setFill()
            cloudPart.fill()
        }
    }

    private func drawPine(at base: CGPoint, scale: CGFloat) {
        let tree = NSBezierPath()
        tree.move(to: CGPoint(x: base.x, y: base.y + 15 * scale))
        tree.line(to: CGPoint(x: base.x - 5 * scale, y: base.y + 5 * scale))
        tree.line(to: CGPoint(x: base.x - 2.4 * scale, y: base.y + 5 * scale))
        tree.line(to: CGPoint(x: base.x - 7 * scale, y: base.y))
        tree.line(to: CGPoint(x: base.x + 7 * scale, y: base.y))
        tree.line(to: CGPoint(x: base.x + 2.4 * scale, y: base.y + 5 * scale))
        tree.line(to: CGPoint(x: base.x + 5 * scale, y: base.y + 5 * scale))
        tree.close()
        NSColor(calibratedRed: 0.09, green: 0.24, blue: 0.24, alpha: 0.95).setFill()
        tree.fill()
    }

    private func drawTruck(curves: [Curve], phase: CGFloat) {
        let scaledProgress = phase * CGFloat(curves.count)
        let curveIndex = min(curves.count - 1, Int(scaledProgress))
        let localProgress = scaledProgress - CGFloat(curveIndex)
        let curve = curves[curveIndex]
        let position = curve.point(at: localProgress)
        let tangent = curve.tangent(at: localProgress)
        let angle = atan2(tangent.y, tangent.x)
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.saveGState()
        context.translateBy(x: position.x, y: position.y + 4)
        context.rotate(by: angle)

        for index in 0..<3 {
            let offset = CGFloat(index) * 5
            let opacity = 0.30 - CGFloat(index) * 0.07
            let size = CGFloat(4 + index)
            let dust = NSBezierPath(ovalIn: CGRect(x: -25 - offset, y: -1 + offset * 0.15, width: size, height: size))
            NSColor.white.withAlphaComponent(opacity).setFill()
            dust.fill()
        }

        let shadow = NSBezierPath(ovalIn: CGRect(x: -22, y: -7, width: 44, height: 6))
        NSColor(calibratedRed: 0.03, green: 0.10, blue: 0.12, alpha: 0.38).setFill()
        shadow.fill()

        let trailer = NSBezierPath(roundedRect: CGRect(x: -20, y: -1, width: 25, height: 14), xRadius: 2, yRadius: 2)
        NSColor(calibratedRed: 0.13, green: 0.67, blue: 0.70, alpha: 1).setFill()
        trailer.fill()
        let trailerTop = NSBezierPath(roundedRect: CGRect(x: -19, y: 11, width: 22, height: 2), xRadius: 1, yRadius: 1)
        NSColor(calibratedRed: 0.47, green: 0.88, blue: 0.84, alpha: 1).setFill()
        trailerTop.fill()
        let trailerLines = NSBezierPath()
        for x in [-15.0, -9.0, -3.0, 3.0] {
            trailerLines.move(to: CGPoint(x: x, y: 1))
            trailerLines.line(to: CGPoint(x: x, y: 10))
        }
        trailerLines.lineWidth = 0.65
        NSColor.white.withAlphaComponent(0.27).setStroke()
        trailerLines.stroke()

        let cab = NSBezierPath()
        cab.move(to: CGPoint(x: 5, y: -1))
        cab.line(to: CGPoint(x: 18, y: -1))
        cab.line(to: CGPoint(x: 19, y: 5))
        cab.line(to: CGPoint(x: 14, y: 13))
        cab.line(to: CGPoint(x: 6, y: 13))
        cab.close()
        NSColor(calibratedRed: 0.95, green: 0.60, blue: 0.25, alpha: 1).setFill()
        cab.fill()
        let windshield = NSBezierPath()
        windshield.move(to: CGPoint(x: 8, y: 8))
        windshield.line(to: CGPoint(x: 13, y: 8))
        windshield.line(to: CGPoint(x: 16.5, y: 12))
        windshield.line(to: CGPoint(x: 8, y: 12))
        windshield.close()
        NSColor(calibratedRed: 0.68, green: 0.86, blue: 0.92, alpha: 1).setFill()
        windshield.fill()
        let bumper = NSBezierPath(roundedRect: CGRect(x: 16, y: -3, width: 5, height: 2), xRadius: 1, yRadius: 1)
        NSColor(calibratedRed: 0.84, green: 0.90, blue: 0.89, alpha: 1).setFill()
        bumper.fill()

        for wheelX in [-13.0, 3.0, 14.0] {
            let wheelCenter = CGPoint(x: wheelX, y: -3)
            context.saveGState()
            context.translateBy(x: wheelCenter.x, y: wheelCenter.y)
            context.rotate(by: Double(phase) * Double.pi * 18)
            let tire = NSBezierPath(ovalIn: CGRect(x: -3.6, y: -3.6, width: 7.2, height: 7.2))
            NSColor(calibratedRed: 0.07, green: 0.12, blue: 0.15, alpha: 1).setFill()
            tire.fill()
            let hub = NSBezierPath(ovalIn: CGRect(x: -1.65, y: -1.65, width: 3.3, height: 3.3))
            NSColor(calibratedRed: 0.75, green: 0.82, blue: 0.80, alpha: 1).setFill()
            hub.fill()
            context.restoreGState()
        }

        let lights = NSBezierPath(ovalIn: CGRect(x: 18, y: 1, width: 2.3, height: 2.3))
        NSColor(calibratedRed: 1, green: 0.88, blue: 0.52, alpha: 1).setFill()
        lights.fill()
        context.restoreGState()
    }

    private func drawSceneLabels(width: CGFloat, height: CGFloat) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 8, weight: .bold),
            .foregroundColor: NSColor.white.withAlphaComponent(0.94),
            .kern: 1.15
        ]
        ("SUMMIT RUN" as NSString).draw(at: CGPoint(x: 12, y: height - 15), withAttributes: attributes)
        let statusAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 7, weight: .medium),
            .foregroundColor: NSColor.white.withAlphaComponent(0.76),
            .kern: 0.45
        ]
        ("YOUR CUT IS ON THE MOVE" as NSString).draw(at: CGPoint(x: 12, y: height - 26), withAttributes: statusAttributes)
        let badge = NSBezierPath(roundedRect: CGRect(x: width - 65, y: height - 23, width: 53, height: 13), xRadius: 6, yRadius: 6)
        NSColor.white.withAlphaComponent(0.15).setFill()
        badge.fill()
        ("LOCAL RIDE" as NSString).draw(at: CGPoint(x: width - 58, y: height - 20), withAttributes: statusAttributes)
    }

    private func fillPolygon(_ points: [CGPoint], color: NSColor) {
        guard let first = points.first else { return }
        let path = NSBezierPath()
        path.move(to: first)
        for point in points.dropFirst() { path.line(to: point) }
        path.close()
        color.setFill()
        path.fill()
    }

    private func stroke(_ path: NSBezierPath, color: NSColor, width: CGFloat) {
        path.lineWidth = width
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        color.setStroke()
        path.stroke()
    }
}

final class VideoSmartCutPopoverController: NSViewController {
    var onCancel: (() -> Void)?

    override func cancelOperation(_ sender: Any?) {
        onCancel?()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    let popover = NSPopover()
    let sourceField = NSTextField(labelWithString: "No video selected")
    let destinationField = NSTextField(labelWithString: "Desktop")
    let outputNameField = NSTextField(string: "")
    let stageField = NSTextField(labelWithString: "READY")
    let statusField = NSTextField(labelWithString: "Ready")
    let detailField = NSTextField(labelWithString: "Choose a video to get started.")
    let progress = NSProgressIndicator()
    let progressValueField = NSTextField(labelWithString: "Ready")
    let elapsedField = NSTextField(labelWithString: "Elapsed 0:00")
    let processingAnimationView = ProcessingAnimationView(frame: .zero)
    let runButton = NSButton(title: "Create Smart Cut", target: nil, action: nil)
    let silenceSlider = NSSlider(value: 1.25, minValue: 0.75, maxValue: 3.0, target: nil, action: nil)
    let silenceValue = NSTextField(labelWithString: "1.25 s")
    let hardwareEncodingButton = NSButton(checkboxWithTitle: "Use Apple hardware encoding", target: nil, action: nil)

    weak var dropView: DropView?
    var sourceURL: URL?
    var destinationURL: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
    var processingStartedAt: Date?
    var elapsedTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let statusButton = statusItem?.button {
            statusButton.image = NSImage(systemSymbolName: "film.stack", accessibilityDescription: "Video Smart Cut")
                ?? NSImage(systemSymbolName: "film", accessibilityDescription: "Video Smart Cut")
            statusButton.toolTip = "Video Smart Cut"
            statusButton.setAccessibilityLabel("Video Smart Cut")
            statusButton.target = self
            statusButton.action = #selector(togglePopoverAction)
        }
        popover.behavior = .applicationDefined

        let content = NSView()
        content.translatesAutoresizingMaskIntoConstraints = true

        let brandMark = NSView()
        brandMark.wantsLayer = true
        brandMark.layer?.cornerRadius = 14
        brandMark.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.14).cgColor
        let brandIcon = NSImageView()
        brandIcon.image = NSImage(systemSymbolName: "film", accessibilityDescription: "Video Smart Cut")
        brandIcon.contentTintColor = .controlAccentColor
        brandIcon.translatesAutoresizingMaskIntoConstraints = false
        brandMark.addSubview(brandIcon)
        NSLayoutConstraint.activate([
            brandMark.widthAnchor.constraint(equalToConstant: 48),
            brandMark.heightAnchor.constraint(equalToConstant: 48),
            brandIcon.centerXAnchor.constraint(equalTo: brandMark.centerXAnchor),
            brandIcon.centerYAnchor.constraint(equalTo: brandMark.centerYAnchor),
            brandIcon.widthAnchor.constraint(equalToConstant: 25),
            brandIcon.heightAnchor.constraint(equalToConstant: 25)
        ])

        let title = NSTextField(labelWithString: "Video Smart Cut")
        title.font = .systemFont(ofSize: 23, weight: .bold)

        let subtitle = NSTextField(labelWithString: "Clean, natural edits—processed locally on your Mac.")
        subtitle.font = .systemFont(ofSize: 12)
        subtitle.textColor = .secondaryLabelColor
        let titleStack = NSStackView(views: [title, subtitle])
        titleStack.orientation = .vertical
        titleStack.alignment = .leading
        titleStack.spacing = 4

        let drop = DropView()
        drop.translatesAutoresizingMaskIntoConstraints = false
        drop.onFile = { [weak self] url in self?.setSource(url) }
        dropView = drop

        let chooseVideo = NSButton(title: "Choose video…", target: self, action: #selector(chooseVideoAction))
        chooseVideo.bezelStyle = .rounded
        chooseVideo.toolTip = "Choose an MP4, MOV, M4V, or MKV video."
        chooseVideo.setAccessibilityHelp("Choose a video file to edit.")

        let chooseDestination = NSButton(title: "Change…", target: self, action: #selector(chooseDestinationAction))
        chooseDestination.bezelStyle = .rounded
        chooseDestination.toolTip = "Choose where the edited video will be saved."
        chooseDestination.setAccessibilityHelp("Choose the folder where the edited video will be saved.")

        sourceField.lineBreakMode = .byTruncatingMiddle
        destinationField.lineBreakMode = .byTruncatingMiddle
        sourceField.font = .systemFont(ofSize: 14, weight: .semibold)
        sourceField.setAccessibilityLabel("Selected video")
        sourceField.setAccessibilityValue("No video selected" as NSString)
        sourceField.setAccessibilityHelp("Drop a video here or use Choose video.")
        destinationField.font = .systemFont(ofSize: 14, weight: .medium)
        destinationField.setAccessibilityLabel("Export folder")
        destinationField.setAccessibilityValue(destinationURL.path as NSString)
        destinationField.toolTip = destinationURL.path
        outputNameField.font = .systemFont(ofSize: 14)
        outputNameField.placeholderString = "Name for your edited video"
        outputNameField.setAccessibilityLabel("Output video name")
        outputNameField.setAccessibilityHelp("Enter the name for the rendered MP4. If the name already exists, a numbered copy will be saved instead.")

        silenceSlider.target = self
        silenceSlider.action = #selector(sliderChanged)
        silenceSlider.setAccessibilityLabel("Silence cut threshold")
        silenceSlider.setAccessibilityHelp("Remove pauses longer than this duration. Lower values keep more of the original audio.")
        silenceSlider.widthAnchor.constraint(greaterThanOrEqualToConstant: 130).isActive = true
        silenceValue.font = .systemFont(ofSize: 14, weight: .semibold)
        silenceValue.alignment = .right
        silenceValue.widthAnchor.constraint(equalToConstant: 54).isActive = true
        silenceValue.setAccessibilityLabel("Current silence threshold")
        hardwareEncodingButton.state = .on
        hardwareEncodingButton.setAccessibilityHelp("Uses this Mac's VideoToolbox H.264 hardware encoder to reduce CPU use. Uncheck to use software x264 encoding.")
        let hardwareEncodingHelp = NSTextField(labelWithString: "Lower CPU use; output size and quality may differ from software encoding.")
        hardwareEncodingHelp.font = .systemFont(ofSize: 12)
        hardwareEncodingHelp.textColor = .secondaryLabelColor
        let hardwareEncodingOption = NSStackView(views: [hardwareEncodingButton, hardwareEncodingHelp])
        hardwareEncodingOption.orientation = .vertical
        hardwareEncodingOption.alignment = .leading
        hardwareEncodingOption.spacing = 3

        let outputNameLabel = NSTextField(labelWithString: "Name the finished video")
        outputNameLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        outputNameLabel.textColor = .secondaryLabelColor
        let outputNameHelp = NSTextField(labelWithString: "Saved as MP4; a number is added if that name already exists.")
        outputNameHelp.font = .systemFont(ofSize: 12)
        outputNameHelp.textColor = .secondaryLabelColor
        let outputNameContent = NSStackView(views: [outputNameLabel, outputNameField, outputNameHelp])
        outputNameContent.orientation = .vertical
        outputNameContent.alignment = .leading
        outputNameContent.spacing = 5

        runButton.target = self
        runButton.action = #selector(runAction)
        runButton.keyEquivalent = "\r"
        runButton.bezelStyle = .rounded
        runButton.controlSize = .large
        runButton.image = NSImage(systemSymbolName: "scissors", accessibilityDescription: "")
        runButton.imagePosition = .imageLeading
        runButton.isEnabled = false
        runButton.setAccessibilityHelp("Transcribe the selected video locally and remove long pauses.")

        progress.style = .bar
        progress.controlSize = .small
        progress.minValue = 0
        progress.maxValue = 100
        progress.doubleValue = 0
        progress.setAccessibilityLabel("Current stage progress")

        stageField.font = .systemFont(ofSize: 11, weight: .bold)
        stageField.textColor = .controlAccentColor
        statusField.font = .systemFont(ofSize: 19, weight: .semibold)
        statusField.setAccessibilityLabel("Processing status")
        detailField.font = .systemFont(ofSize: 13)
        detailField.textColor = .secondaryLabelColor
        detailField.lineBreakMode = .byTruncatingTail
        detailField.setAccessibilityLabel("Progress details")
        progressValueField.font = .systemFont(ofSize: 22, weight: .bold)
        progressValueField.textColor = .controlAccentColor
        progressValueField.alignment = .right
        progressValueField.setAccessibilityLabel("Stage completion")
        elapsedField.font = .systemFont(ofSize: 12)
        elapsedField.textColor = .secondaryLabelColor
        elapsedField.alignment = .right
        elapsedField.isHidden = true
        elapsedField.setAccessibilityLabel("Elapsed time")

        let headerSpacer = NSView()
        let closePopoverButton = NSButton(image: NSImage(systemSymbolName: "xmark", accessibilityDescription: "Close Video Smart Cut") ?? NSImage(), target: self, action: #selector(closePopoverAction))
        closePopoverButton.bezelStyle = .regularSquare
        closePopoverButton.isBordered = false
        closePopoverButton.contentTintColor = .secondaryLabelColor
        closePopoverButton.setAccessibilityLabel("Close Video Smart Cut")
        closePopoverButton.setAccessibilityHelp("Close this panel. Click the film icon in the menu bar to reopen it.")
        let header = NSStackView(views: [brandMark, titleStack, headerSpacer, closePopoverButton])
        header.orientation = .horizontal
        header.alignment = .centerY
        header.spacing = 14

        let sourceHeader = sectionHeader(step: "01", title: "Choose a video", subtitle: "Drop a file below or browse your Mac.", action: chooseVideo)
        let sourceContent = NSStackView(views: [sourceHeader, drop])
        sourceContent.orientation = .vertical
        sourceContent.spacing = 10
        sourceHeader.widthAnchor.constraint(equalTo: sourceContent.widthAnchor).isActive = true
        drop.widthAnchor.constraint(equalTo: sourceContent.widthAnchor).isActive = true
        drop.heightAnchor.constraint(equalToConstant: 64).isActive = true
        let sourceCard = CardView(content: sourceContent)

        let destinationFieldLabel = NSTextField(labelWithString: "Save finished video to")
        destinationFieldLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        destinationFieldLabel.textColor = .secondaryLabelColor
        let destinationInfo = NSStackView(views: [destinationFieldLabel, destinationField])
        destinationInfo.orientation = .vertical
        destinationInfo.alignment = .leading
        destinationInfo.spacing = 5
        destinationInfo.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let destinationRow = NSStackView(views: [destinationInfo, chooseDestination])
        destinationRow.orientation = .horizontal
        destinationRow.alignment = .centerY
        destinationRow.spacing = 14

        let thresholdTitle = NSTextField(labelWithString: "Cut pauses longer than")
        thresholdTitle.font = .systemFont(ofSize: 14, weight: .semibold)
        let thresholdHelp = NSTextField(labelWithString: "A longer threshold keeps more natural pauses.")
        thresholdHelp.font = .systemFont(ofSize: 12)
        thresholdHelp.textColor = .secondaryLabelColor
        let thresholdInfo = NSStackView(views: [thresholdTitle, thresholdHelp])
        thresholdInfo.orientation = .vertical
        thresholdInfo.alignment = .leading
        thresholdInfo.spacing = 4
        thresholdInfo.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let thresholdRow = NSStackView(views: [thresholdInfo, silenceSlider, silenceValue])
        thresholdRow.orientation = .horizontal
        thresholdRow.alignment = .centerY
        thresholdRow.spacing = 14

        let divider = NSBox()
        divider.boxType = .separator
        let settingsHeader = sectionHeader(step: "02", title: "Export & cut settings", subtitle: "Choose a destination and tune how much silence to remove.")
        let settingsContent = NSStackView(views: [settingsHeader, destinationRow, outputNameContent, divider, thresholdRow, hardwareEncodingOption])
        settingsContent.orientation = .vertical
        settingsContent.spacing = 8
        settingsHeader.widthAnchor.constraint(equalTo: settingsContent.widthAnchor).isActive = true
        destinationRow.widthAnchor.constraint(equalTo: settingsContent.widthAnchor).isActive = true
        outputNameContent.widthAnchor.constraint(equalTo: settingsContent.widthAnchor).isActive = true
        outputNameField.widthAnchor.constraint(equalTo: outputNameContent.widthAnchor).isActive = true
        divider.widthAnchor.constraint(equalTo: settingsContent.widthAnchor).isActive = true
        thresholdRow.widthAnchor.constraint(equalTo: settingsContent.widthAnchor).isActive = true
        hardwareEncodingOption.widthAnchor.constraint(equalTo: settingsContent.widthAnchor).isActive = true
        let settingsCard = CardView(content: settingsContent)

        let elapsedSpacer = NSView()
        let progressTop = NSStackView(views: [stageField, elapsedSpacer, elapsedField])
        progressTop.orientation = .horizontal
        progressTop.alignment = .centerY
        processingAnimationView.translatesAutoresizingMaskIntoConstraints = false
        processingAnimationView.isHidden = true
        let progressTitleSpacer = NSView()
        let progressTitleRow = NSStackView(views: [statusField, progressTitleSpacer, progressValueField])
        progressTitleRow.orientation = .horizontal
        progressTitleRow.alignment = .centerY
        progressTitleRow.spacing = 10
        processingAnimationView.translatesAutoresizingMaskIntoConstraints = false
        processingAnimationView.isHidden = true
        let progressContent = NSStackView(views: [progressTop, progressTitleRow, processingAnimationView, detailField, progress])
        progressContent.orientation = .vertical
        progressContent.spacing = 8
        progressTop.widthAnchor.constraint(equalTo: progressContent.widthAnchor).isActive = true
        progressTitleRow.widthAnchor.constraint(equalTo: progressContent.widthAnchor).isActive = true
        processingAnimationView.widthAnchor.constraint(equalTo: progressContent.widthAnchor).isActive = true
        processingAnimationView.heightAnchor.constraint(equalToConstant: 82).isActive = true
        detailField.widthAnchor.constraint(equalTo: progressContent.widthAnchor).isActive = true
        progress.widthAnchor.constraint(equalTo: progressContent.widthAnchor).isActive = true
        let progressCard = CardView(content: progressContent)

        let localIcon = NSImageView(image: NSImage(systemSymbolName: "lock.shield", accessibilityDescription: "Local processing") ?? NSImage())
        localIcon.contentTintColor = .secondaryLabelColor
        let localLabel = NSTextField(labelWithString: "Your video stays on this Mac")
        localLabel.font = .systemFont(ofSize: 12)
        localLabel.textColor = .secondaryLabelColor
        let localNote = NSStackView(views: [localIcon, localLabel])
        localNote.orientation = .horizontal
        localNote.alignment = .centerY
        localNote.spacing = 7
        let actionSpacer = NSView()
        let quitButton = NSButton(title: "Quit", target: NSApp, action: #selector(NSApplication.terminate(_:)))
        quitButton.bezelStyle = .rounded
        quitButton.setAccessibilityHelp("Quit Video Smart Cut and remove its menu bar icon.")
        let actionRow = NSStackView(views: [localNote, actionSpacer, quitButton, runButton])
        actionRow.orientation = .horizontal
        actionRow.alignment = .centerY
        actionRow.spacing = 12

        let stack = NSStackView(views: [header, sourceCard, settingsCard, progressCard, actionRow])
        stack.orientation = .vertical
        stack.spacing = 10
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 18),
            header.widthAnchor.constraint(equalTo: stack.widthAnchor),
            sourceCard.widthAnchor.constraint(equalTo: stack.widthAnchor),
            settingsCard.widthAnchor.constraint(equalTo: stack.widthAnchor),
            progressCard.widthAnchor.constraint(equalTo: stack.widthAnchor),
            actionRow.widthAnchor.constraint(equalTo: stack.widthAnchor),
            closePopoverButton.widthAnchor.constraint(equalToConstant: 28),
            closePopoverButton.heightAnchor.constraint(equalToConstant: 28),
            localIcon.widthAnchor.constraint(equalToConstant: 15),
            localIcon.heightAnchor.constraint(equalToConstant: 15),
            runButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 42)
        ])

        destinationField.stringValue = destinationURL.lastPathComponent
        outputNameField.stringValue = ""
        progressValueField.stringValue = "READY"
        let contentController = VideoSmartCutPopoverController()
        contentController.onCancel = { [weak self] in self?.closePopoverAction() }
        contentController.view = content
        contentController.preferredContentSize = NSSize(width: 520, height: 780)
        popover.contentViewController = contentController
        popover.contentSize = NSSize(width: 520, height: 780)
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        if let first = filenames.first { setSource(URL(fileURLWithPath: first)) }
        reopenPopoverAfterPanelDismissal()
        sender.reply(toOpenOrPrint: .success)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    @objc func togglePopoverAction() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopoverIfNeeded()
        }
    }

    @objc func closePopoverAction() {
        popover.performClose(nil)
    }

    func showPopoverIfNeeded() {
        guard !popover.isShown, let statusButton = statusItem?.button else { return }
        popover.show(relativeTo: statusButton.bounds, of: statusButton, preferredEdge: .minY)
    }

    func reopenPopoverAfterPanelDismissal() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            guard let self, let statusButton = self.statusItem?.button else { return }
            let wasAnimating = self.popover.animates
            self.popover.animates = false
            self.popover.close()
            self.popover.animates = wasAnimating
            if #available(macOS 14.0, *) {
                NSApp.activate()
            } else {
                NSApp.activate(ignoringOtherApps: true)
            }
            self.popover.show(relativeTo: statusButton.bounds, of: statusButton, preferredEdge: .minY)
        }
    }

    func sectionHeader(step: String, title: String, subtitle: String, action: NSView? = nil) -> NSStackView {
        let badge = NSView()
        badge.wantsLayer = true
        badge.layer?.cornerRadius = 11
        badge.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.14).cgColor
        badge.translatesAutoresizingMaskIntoConstraints = false
        let badgeLabel = NSTextField(labelWithString: step)
        badgeLabel.font = .systemFont(ofSize: 11, weight: .bold)
        badgeLabel.textColor = .controlAccentColor
        badgeLabel.alignment = .center
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badge.addSubview(badgeLabel)
        NSLayoutConstraint.activate([
            badge.widthAnchor.constraint(equalToConstant: 34),
            badge.heightAnchor.constraint(equalToConstant: 34),
            badgeLabel.centerXAnchor.constraint(equalTo: badge.centerXAnchor),
            badgeLabel.centerYAnchor.constraint(equalTo: badge.centerYAnchor)
        ])

        let heading = NSTextField(labelWithString: title)
        heading.font = .systemFont(ofSize: 16, weight: .semibold)
        let description = NSTextField(labelWithString: subtitle)
        description.font = .systemFont(ofSize: 12)
        description.textColor = .secondaryLabelColor
        let copy = NSStackView(views: [heading, description])
        copy.orientation = .vertical
        copy.alignment = .leading
        copy.spacing = 3
        copy.setContentHuggingPriority(.defaultLow, for: .horizontal)

        var views: [NSView] = [badge, copy]
        if let action { views.append(action) }
        let row = NSStackView(views: views)
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 11
        return row
    }

    func setSource(_ url: URL) {
        let allowed = ["mp4", "mov", "m4v", "mkv"]
        guard allowed.contains(url.pathExtension.lowercased()) else {
            showAlert("Unsupported file", "Choose an MP4, MOV, M4V, or MKV video.")
            return
        }
        sourceURL = url
        sourceField.stringValue = url.lastPathComponent
        sourceField.toolTip = url.path
        sourceField.setAccessibilityValue(url.path as NSString)
        outputNameField.stringValue = "\(url.deletingPathExtension().lastPathComponent)_SMART_EDIT"
        dropView?.setSelectedVideo(url)
        runButton.isEnabled = true
        stageField.stringValue = "READY"
        statusField.stringValue = "Ready to create your edit"
        statusField.setAccessibilityValue("Ready to create your edit" as NSString)
        detailField.stringValue = "Your selected video is ready."
        progressValueField.stringValue = "READY"
        progress.isIndeterminate = false
        progress.doubleValue = 0
    }

    @objc func chooseVideoAction() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.movie]
        panel.allowsMultipleSelection = false
        panel.begin { [weak self] response in
            guard let self else { return }
            if response == .OK, let url = panel.url { self.setSource(url) }
            self.reopenPopoverAfterPanelDismissal()
        }
    }

    @objc func chooseDestinationAction() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.prompt = "Choose"
        panel.begin { [weak self] response in
            guard let self else { return }
            if response == .OK, let url = panel.url {
                self.destinationURL = url
                self.destinationField.stringValue = url.lastPathComponent
                self.destinationField.toolTip = url.path
                self.destinationField.setAccessibilityValue(url.path as NSString)
            }
            self.reopenPopoverAfterPanelDismissal()
        }
    }

    @objc func sliderChanged() {
        silenceValue.stringValue = String(format: "%.2f s", silenceSlider.doubleValue)
    }

    @objc func runAction() {
        guard let source = sourceURL else {
            showAlert("Choose a video", "Drop a video into the window or click Choose Video.")
            return
        }

        let outputBaseName: String
        do {
            outputBaseName = try normalizedOutputBaseName(outputNameField.stringValue)
        } catch {
            showAlert("Enter a video name", error.localizedDescription)
            return
        }

        let mlx = findExecutable(["\(NSHomeDirectory())/.local/bin/mlx_whisper", "/opt/homebrew/bin/mlx_whisper", "/usr/local/bin/mlx_whisper"])
        let ffmpeg = findExecutable(["/opt/homebrew/bin/ffmpeg", "/usr/local/bin/ffmpeg", "/usr/bin/ffmpeg"])
        let ffprobe = findExecutable(["/opt/homebrew/bin/ffprobe", "/usr/local/bin/ffprobe", "/usr/bin/ffprobe"])

        guard let mlx else { showAlert("mlx_whisper not found", "Install it with: pipx install mlx-whisper"); return }
        guard let ffmpeg, let ffprobe else { showAlert("FFmpeg not found", "Install it with Homebrew: brew install ffmpeg"); return }

        setBusy(true)
        let threshold = silenceSlider.doubleValue
        let useHardwareEncoding = hardwareEncodingButton.state == .on
        let destination = destinationURL

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let output = try self.process(source: source, destination: destination, outputBaseName: outputBaseName, threshold: threshold, useHardwareEncoding: useHardwareEncoding, mlx: mlx, ffmpeg: ffmpeg, ffprobe: ffprobe)
                DispatchQueue.main.async {
                    self.setBusy(false)
                    self.updateProgress(stage: "COMPLETE", title: "Your smart cut is ready", detail: output.lastPathComponent, fraction: 1)
                    NSWorkspace.shared.activateFileViewerSelecting([output])
                    self.showAlert("Finished", "Your edited video is ready:\n\n\(output.path)")
                }
            } catch {
                DispatchQueue.main.async {
                    self.setBusy(false)
                    self.stageField.stringValue = "NEEDS ATTENTION"
                    self.statusField.stringValue = "The edit couldn't finish"
                    self.statusField.setAccessibilityValue("The edit couldn't finish" as NSString)
                    self.detailField.stringValue = "Review the error details, then try again."
                    self.progress.stopAnimation(nil)
                    self.progress.isIndeterminate = false
                    self.progressValueField.stringValue = "—"
                    self.showAlert("Video Smart Cut failed", error.localizedDescription)
                }
            }
        }
    }

    func normalizedOutputBaseName(_ proposedName: String) throws -> String {
        let trimmedName = proposedName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw NSError(domain: "VideoSmartCut", code: 6, userInfo: [NSLocalizedDescriptionKey: "Type a name for the finished video before creating the smart cut."])
        }

        var filename = URL(fileURLWithPath: trimmedName).lastPathComponent
        let extensionName = URL(fileURLWithPath: filename).pathExtension.lowercased()
        if ["mp4", "mov", "m4v", "mkv"].contains(extensionName) {
            filename = URL(fileURLWithPath: filename).deletingPathExtension().lastPathComponent
        }
        let invalidFilenameCharacters = CharacterSet(charactersIn: "/:")
        filename = String(filename.unicodeScalars.filter {
            !CharacterSet.controlCharacters.contains($0) && !invalidFilenameCharacters.contains($0)
        }).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !filename.isEmpty, filename != ".", filename != ".." else {
            throw NSError(domain: "VideoSmartCut", code: 7, userInfo: [NSLocalizedDescriptionKey: "Enter a name that contains at least one valid filename character."])
        }
        return filename
    }

    func reserveOutputURL(destination: URL, baseName: String) throws -> URL {
        var suffix = 1
        while true {
            let filename = suffix == 1 ? "\(baseName).mp4" : "\(baseName)_\(suffix).mp4"
            let candidate = destination.appendingPathComponent(filename)
            let descriptor = Darwin.open(candidate.path, O_WRONLY | O_CREAT | O_EXCL, mode_t(S_IRUSR | S_IWUSR))
            if descriptor >= 0 {
                Darwin.close(descriptor)
                return candidate
            }

            let errorCode = errno
            if errorCode == EEXIST {
                suffix += 1
                continue
            }
            let reason = String(cString: strerror(errorCode))
            throw NSError(domain: "VideoSmartCut", code: Int(errorCode), userInfo: [NSLocalizedDescriptionKey: "Could not reserve the finished video name in \(destination.path): \(reason)"])
        }
    }

    func process(source: URL, destination: URL, outputBaseName: String, threshold: Double, useHardwareEncoding: Bool, mlx: String, ffmpeg: String, ffprobe: String) throws -> URL {
        let fm = FileManager.default
        let temp = fm.temporaryDirectory.appendingPathComponent("VideoSmartCut-\(UUID().uuidString)")
        try fm.createDirectory(at: temp, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: temp) }

        updateProgress(stage: "STEP 1 OF 3 · TRANSCRIBE", title: "Transcribing your video", detail: "Loading Whisper and preparing word timestamps…", fraction: nil)
        let whisperProgress = WhisperProgressParser()
        let whisperLog = try run(mlx, [
                      "--model", "mlx-community/whisper-large-v3-turbo",
                      "--language", "en",
                      "--word-timestamps", "True",
                      "--verbose", "False",
                      "--output-format", "json",
                      "--output-dir", temp.path,
                      "--output-name", "transcript",
                      source.path], currentDirectory: temp, onOutput: { text in
            for fraction in whisperProgress.append(text) {
                self.updateProgress(stage: "STEP 1 OF 3 · TRANSCRIBE", title: "Transcribing your video", detail: "Whisper is converting speech into timestamped words.", fraction: fraction)
            }
        })
        updateProgress(stage: "STEP 1 OF 3 · TRANSCRIBE", title: "Transcription complete", detail: "Preparing the speech map for silence detection…", fraction: 1)

        // mlx-whisper normally writes transcript.json to --output-dir. Be tolerant of
        // writer/version quirks by checking the requested path first, then any JSON
        // created in the temporary working directory.
        let requestedJSON = temp.appendingPathComponent("transcript.json")
        let jsonURL: URL
        if fm.fileExists(atPath: requestedJSON.path) {
            jsonURL = requestedJSON
        } else if let discovered = try fm.contentsOfDirectory(at: temp, includingPropertiesForKeys: nil)
            .first(where: { $0.pathExtension.lowercased() == "json" }) {
            jsonURL = discovered
        } else {
            let names = (try? fm.contentsOfDirectory(atPath: temp.path).joined(separator: ", ")) ?? "(unable to list temp folder)"
            let tail = String(whisperLog.suffix(2500))
            throw NSError(domain: "VideoSmartCut", code: 1, userInfo: [NSLocalizedDescriptionKey: "Whisper exited successfully, but no JSON transcript was created.\n\nTemporary folder contained: \(names)\n\nWhisper output:\n\(tail)"])
        }

        let data = try Data(contentsOf: jsonURL)
        let transcript = try WhisperJSON.decode(from: data)
        var words: [(Double, Double)] = []
        for segment in transcript.segments {
            for word in segment.words ?? [] where word.end > word.start {
                words.append((word.start, word.end))
            }
        }
        guard let first = words.first else {
            throw NSError(domain: "VideoSmartCut", code: 2, userInfo: [NSLocalizedDescriptionKey: "No word timestamps were found in the transcript."])
        }

        updateProgress(stage: "STEP 2 OF 3 · ANALYZE", title: "Finding pauses", detail: "Measuring the video and scanning spoken words…", fraction: nil)
        let durationText = try capture(ffprobe, ["-v", "error", "-show_entries", "format=duration", "-of", "default=noprint_wrappers=1:nokey=1", source.path])
        guard let duration = Double(durationText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw NSError(domain: "VideoSmartCut", code: 3, userInfo: [NSLocalizedDescriptionKey: "Could not determine video duration."])
        }

        let padBefore = 0.20
        let padAfter = 0.30
        var chunks: [(Double, Double)] = []
        var chunkStart = max(0, first.0 - padBefore)
        var chunkEnd = min(duration, first.1 + padAfter)

        for (index, word) in words.enumerated().dropFirst() {
            let start = word.0
            let end = word.1
            let paddedStart = max(0, start - padBefore)
            let paddedEnd = min(duration, end + padAfter)
            let gap = paddedStart - chunkEnd
            if gap <= threshold {
                chunkEnd = max(chunkEnd, paddedEnd)
            } else {
                if chunkEnd - chunkStart >= 0.05 { chunks.append((chunkStart, chunkEnd)) }
                chunkStart = paddedStart
                chunkEnd = paddedEnd
            }
            if index == 1 || index % 250 == 0 {
                let fraction = Double(index) / Double(words.count)
                updateProgress(stage: "STEP 2 OF 3 · ANALYZE", title: "Finding pauses", detail: "Scanning word \(index) of \(words.count)…", fraction: fraction)
            }
        }
        if chunkEnd - chunkStart >= 0.05 { chunks.append((chunkStart, chunkEnd)) }
        updateProgress(stage: "STEP 2 OF 3 · ANALYZE", title: "Pause analysis complete", detail: "Keeping \(chunks.count) spoken sections in your edit.", fraction: 1)

        var filterLines: [String] = []
        var concat = ""
        for (i, c) in chunks.enumerated() {
            filterLines.append(String(format: "[0:v]trim=start=%.3f:end=%.3f,setpts=PTS-STARTPTS[v%d]", c.0, c.1, i))
            filterLines.append(String(format: "[0:a]atrim=start=%.3f:end=%.3f,asetpts=PTS-STARTPTS[a%d]", c.0, c.1, i))
            concat += "[v\(i)][a\(i)]"
        }
        filterLines.append("\(concat)concat=n=\(chunks.count):v=1:a=1[vout][aout]")
        let filterURL = temp.appendingPathComponent("filters.txt")
        try filterLines.joined(separator: ";\n").write(to: filterURL, atomically: true, encoding: .utf8)

        let output = try reserveOutputURL(destination: destination, baseName: outputBaseName)
        var outputIsComplete = false
        defer {
            if !outputIsComplete { try? fm.removeItem(at: output) }
        }

        let renderDuration = chunks.reduce(0.0) { $0 + ($1.1 - $1.0) }
        let ffmpegProgress = FFmpegProgressParser(duration: renderDuration)
        let videoEncodingArguments: [String]
        let encoderDescription: String
        if useHardwareEncoding {
            let reportedBitrate = try? capture(ffprobe, [
                "-v", "error", "-select_streams", "v:0",
                "-show_entries", "stream=bit_rate",
                "-of", "default=noprint_wrappers=1:nokey=1", source.path
            ])
            let sourceBitrate = reportedBitrate
                .flatMap { Double($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
                .flatMap { $0.isFinite && $0 > 0 ? $0 : nil } ?? 6_000_000
            let targetBitrate = Int(min(40_000_000, max(2_000_000, sourceBitrate * 1.5)))
            videoEncodingArguments = ["-c:v", "h264_videotoolbox", "-b:v", String(targetBitrate), "-allow_sw", "0"]
            encoderDescription = "Apple hardware H.264 encoding"
        } else {
            videoEncodingArguments = ["-c:v", "libx264", "-preset", "medium", "-crf", "18"]
            encoderDescription = "software x264 encoding"
        }
        updateProgress(stage: "STEP 3 OF 3 · RENDER", title: "Rendering your smart cut", detail: "Using \(encoderDescription) for \(chunks.count) spoken sections…", fraction: 0)
        try run(ffmpeg, ["-y", "-i", source.path,
                         "-/filter_complex", filterURL.path,
                         "-map", "[vout]", "-map", "[aout]",
                         ] + videoEncodingArguments + [
                         "-pix_fmt", "yuv420p",
                         "-c:a", "aac", "-b:a", "192k",
                         "-movflags", "+faststart",
                         "-stats_period", "0.5", "-progress", "pipe:1", "-nostats",
                         output.path], onOutput: { text in
            for fraction in ffmpegProgress.append(text) {
                let renderedSeconds = fraction * renderDuration
                let detail = "Rendering · \(self.formatTime(renderedSeconds)) of \(self.formatTime(renderDuration))"
                self.updateProgress(stage: "STEP 3 OF 3 · RENDER", title: "Rendering your smart cut", detail: detail, fraction: fraction)
            }
        })
        let outputSize = try output.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        guard outputSize > 0 else {
            throw NSError(domain: "VideoSmartCut", code: 8, userInfo: [NSLocalizedDescriptionKey: "FFmpeg finished without writing the edited video."])
        }
        outputIsComplete = true
        updateProgress(stage: "STEP 3 OF 3 · RENDER", title: "Rendering complete", detail: "Your edited video is ready to save.", fraction: 1)
        return output
    }

    func updateProgress(stage: String, title: String, detail: String, fraction: Double?) {
        DispatchQueue.main.async {
            self.stageField.stringValue = stage
            self.stageField.setAccessibilityValue(stage as NSString)
            self.statusField.stringValue = title
            self.statusField.setAccessibilityValue(title as NSString)
            self.detailField.stringValue = detail
            self.detailField.setAccessibilityValue(detail as NSString)

            if let fraction {
                let clamped = min(1, max(0, fraction))
                self.progress.stopAnimation(nil)
                self.progress.isIndeterminate = false
                self.progress.doubleValue = clamped * 100
                let percent = Int((clamped * 100).rounded())
                let value = "\(percent)%"
                self.progressValueField.stringValue = value
                self.progressValueField.setAccessibilityValue(value as NSString)
                self.progress.setAccessibilityValue(NSNumber(value: percent))
            } else {
                self.progress.doubleValue = 0
                self.progress.isIndeterminate = true
                self.progress.startAnimation(nil)
                self.progressValueField.stringValue = "Working…"
                self.progressValueField.setAccessibilityValue("Working" as NSString)
                self.progress.setAccessibilityValue("Indeterminate" as NSString)
            }
        }
    }

    func setBusy(_ busy: Bool) {
        runButton.isEnabled = !busy && sourceURL != nil
        outputNameField.isEditable = !busy
        processingAnimationView.isHidden = !busy
        if busy {
            processingAnimationView.startAnimating()
            processingStartedAt = Date()
            elapsedField.isHidden = false
            updateElapsedLabel()
            elapsedTimer?.invalidate()
            elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                self?.updateElapsedLabel()
            }
        } else {
            processingAnimationView.stopAnimating()
            updateElapsedLabel()
            elapsedTimer?.invalidate()
            elapsedTimer = nil
            processingStartedAt = nil
        }
    }

    func updateElapsedLabel() {
        guard let processingStartedAt else { return }
        let elapsed = formatTime(Date().timeIntervalSince(processingStartedAt))
        elapsedField.stringValue = "Elapsed \(elapsed)"
        elapsedField.setAccessibilityValue(elapsed as NSString)
    }

    func formatTime(_ seconds: Double) -> String {
        let total = max(0, Int(seconds))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let remainingSeconds = total % 60
        if hours > 0 { return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds) }
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    func showAlert(_ title: String, _ message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    func findExecutable(_ paths: [String]) -> String? {
        for path in paths where FileManager.default.isExecutableFile(atPath: path) { return path }
        return nil
    }

    @discardableResult
    func run(_ executable: String, _ arguments: [String], currentDirectory: URL? = nil, onOutput: ((String) -> Void)? = nil) throws -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: executable)
        task.arguments = arguments
        if let currentDirectory { task.currentDirectoryURL = currentDirectory }
        // GUI apps launch with a minimal PATH. Include Homebrew and pipx locations
        // so child processes and their helpers can be resolved consistently.
        var env = ProcessInfo.processInfo.environment
        let extraPath = "\(NSHomeDirectory())/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        env["PATH"] = extraPath + ":" + (env["PATH"] ?? "")
        task.environment = env
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        try task.run()
        let outputBuffer = ProcessOutputBuffer()
        let readerGroup = DispatchGroup()
        readerGroup.enter()
        DispatchQueue.global(qos: .utility).async {
            let reader = pipe.fileHandleForReading
            while true {
                let chunk = reader.availableData
                guard !chunk.isEmpty else { break }
                outputBuffer.append(chunk)
                onOutput?(String(decoding: chunk, as: UTF8.self))
            }
            readerGroup.leave()
        }
        task.waitUntilExit()
        readerGroup.wait()
        let text = String(data: outputBuffer.value(), encoding: .utf8) ?? ""
        if task.terminationStatus != 0 {
            throw NSError(domain: "VideoSmartCut", code: Int(task.terminationStatus), userInfo: [NSLocalizedDescriptionKey: text.isEmpty ? "A required command failed." : String(text.suffix(5000))])
        }
        return text
    }

    func capture(_ executable: String, _ arguments: [String]) throws -> String {
        try run(executable, arguments)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
