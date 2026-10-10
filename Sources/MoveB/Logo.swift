import AppKit

/// MoveB's logo, the same keycap as `docs/icon.png`: a key outline holding a
/// two-thirds pane and a lighter one-third pane. Drawn as a template image, so
/// it takes the menu bar's or the image view's tint and works in light and dark mode.
enum Logo {
    static func image(width: CGFloat, height: CGFloat) -> NSImage {
        let image = NSImage(size: NSSize(width: width, height: height), flipped: false) { rect in
            let side = min(width, height)
            let line = (side * 0.09).rounded()
            let cap = rect.insetBy(dx: line / 2, dy: line / 2)
            let outline = NSBezierPath(roundedRect: cap, xRadius: side * 0.2, yRadius: side * 0.2)
            outline.lineWidth = line
            NSColor.black.setStroke()
            outline.stroke()

            let paneY = rect.minY + rect.height * 0.2
            let paneHeight = rect.height * 0.6
            let radius = side * 0.05
            NSColor.black.setFill()
            NSBezierPath(roundedRect: NSRect(x: rect.width * 0.2, y: paneY, width: rect.width * 0.38, height: paneHeight),
                         xRadius: radius, yRadius: radius).fill()
            NSColor.black.withAlphaComponent(0.35).setFill()
            NSBezierPath(roundedRect: NSRect(x: rect.width * 0.62, y: paneY, width: rect.width * 0.18, height: paneHeight),
                         xRadius: radius, yRadius: radius).fill()
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "MoveB"
        return image
    }
}
