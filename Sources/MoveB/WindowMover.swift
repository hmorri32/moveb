import AppKit

/// Moves other apps' windows through the Accessibility API.
///
/// Accessibility uses a top-left origin anchored to the primary screen; Cocoa (NSScreen)
/// uses bottom-left. Everything here converts to Cocoa coordinates for the math and back
/// to Accessibility coordinates to apply.
enum WindowMover {
    enum Placement {
        case leftHalf, rightHalf, leftTwoThirds, fill, center
    }

    static func focusedWindow(of app: NSRunningApplication) -> AXUIElement? {
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &value) == .success,
              let value, CFGetTypeID(value) == AXUIElementGetTypeID()
        else { return nil }
        return (value as! AXUIElement)
    }

    static func screen(containing window: AXUIElement) -> NSScreen? {
        guard let frame = cocoaFrame(of: window) else { return nil }
        return NSScreen.screens.max { overlap(frame, $0.frame) < overlap(frame, $1.frame) }
    }

    private static let centerWidthFraction: CGFloat = 0.78

    static func place(_ window: AXUIElement, _ placement: Placement) {
        guard let visible = screen(containing: window)?.visibleFrame else { return }

        let half = (visible.width / 2).rounded(.down)
        let target: CGRect = switch placement {
        case .leftHalf:
            CGRect(x: visible.minX, y: visible.minY, width: half, height: visible.height)
        case .rightHalf:
            CGRect(x: visible.minX + half, y: visible.minY, width: visible.width - half, height: visible.height)
        case .leftTwoThirds:
            CGRect(x: visible.minX, y: visible.minY, width: (visible.width * 2 / 3).rounded(.down), height: visible.height)
        case .fill:
            visible
        case .center:
            centered(size: CGSize(width: visible.width * centerWidthFraction, height: visible.height), in: visible)
        }
        setFrame(window, cocoa: target)
    }

    private static func centered(size: CGSize, in visible: CGRect) -> CGRect {
        let width = min(size.width, visible.width)
        let height = min(size.height, visible.height)
        return CGRect(
            x: (visible.midX - width / 2).rounded(),
            y: (visible.midY - height / 2).rounded(),
            width: width,
            height: height
        )
    }

    private static func setFrame(_ window: AXUIElement, cocoa frame: CGRect) {
        var position = CGPoint(x: frame.minX, y: primaryScreenHeight - frame.maxY)
        var size = frame.size
        guard let axPosition = AXValueCreate(.cgPoint, &position),
              let axSize = AXValueCreate(.cgSize, &size)
        else { return }

        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, axSize)
        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, axPosition)
        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, axSize)
    }

    private static func cocoaFrame(of window: AXUIElement) -> CGRect? {
        var positionValue: CFTypeRef?
        var sizeValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue) == .success,
              AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue) == .success
        else { return nil }

        var position = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(positionValue as! AXValue, .cgPoint, &position),
              AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
        else { return nil }

        return CGRect(x: position.x, y: primaryScreenHeight - position.y - size.height, width: size.width, height: size.height)
    }

    private static var primaryScreenHeight: CGFloat {
        NSScreen.screens.first?.frame.height ?? 0
    }

    private static func overlap(_ a: CGRect, _ b: CGRect) -> CGFloat {
        let intersection = a.intersection(b)
        return intersection.isNull ? 0 : intersection.width * intersection.height
    }
}
