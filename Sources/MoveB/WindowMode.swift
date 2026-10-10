import AppKit

final class WindowMode {
    private static let timeout: TimeInterval = 3

    private let panel = ModePanel()
    private var target: (app: NSRunningApplication, window: AXUIElement)?
    private var timer: Timer?

    init() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.isActive else { return event }
            self.handle(event)
            return nil
        }
    }

    private var isActive: Bool { target != nil }

    func toggle() {
        isActive ? exit() : enter()
    }

    private func enter() {
        guard let app = NSWorkspace.shared.frontmostApplication,
              app.processIdentifier != ProcessInfo.processInfo.processIdentifier,
              let window = WindowMover.focusedWindow(of: app)
        else {
            NSLog("MoveB: no target window (trusted: %d, frontmost: %@)",
                  AXIsProcessTrusted(), NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "none")
            NSSound.beep()
            return
        }
        target = (app, window)

        panel.show(on: WindowMover.screen(containing: window) ?? NSScreen.main)
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        timer = Timer.scheduledTimer(withTimeInterval: Self.timeout, repeats: false) { [weak self] _ in
            self?.exit()
        }
    }

    private func exit() {
        guard let target else { return }
        self.target = nil
        timer?.invalidate()
        timer = nil
        panel.orderOut(nil)
        target.app.activate()
    }

    private func handle(_ event: NSEvent) {
        guard let target else { return }
        let placement: WindowMover.Placement? = switch event.keyCode {
        case KeyCode.leftArrow: .leftHalf
        case KeyCode.rightArrow: .rightHalf
        case KeyCode.space: .fill
        case KeyCode.one: .leftTwoThirds
        case KeyCode.c: .center
        default: nil
        }
        if let placement {
            WindowMover.place(target.window, placement)
        }
        exit()
    }
}

private final class ModePanel: NSPanel {
    private static let badgeSize: CGFloat = 160

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.borderless],
            backing: .buffered,
            defer: true
        )
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false

        let dim = NSView(frame: NSRect(origin: .zero, size: frame.size))
        dim.wantsLayer = true
        dim.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.2).cgColor

        let size = Self.badgeSize
        let badge = NSVisualEffectView(frame: NSRect(
            x: (dim.bounds.width - size) / 2,
            y: (dim.bounds.height - size) / 2,
            width: size,
            height: size
        ))
        badge.autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin, .maxYMargin]
        badge.material = .hudWindow
        badge.state = .active
        badge.wantsLayer = true
        badge.layer?.cornerRadius = 28
        badge.layer?.masksToBounds = true

        let icon = NSImageView(frame: badge.bounds.insetBy(dx: 40, dy: 40))
        icon.autoresizingMask = [.width, .height]
        icon.image = Logo.image(width: 80, height: 80)
        icon.contentTintColor = .labelColor
        badge.addSubview(icon)

        dim.addSubview(badge)
        contentView = dim
    }

    override var canBecomeKey: Bool { true }

    func show(on screen: NSScreen?) {
        guard let screen else { return }
        setFrame(screen.frame, display: true)
    }
}
