import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowMode: WindowMode!
    private var hotKey: HotKey!
    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = Logo.image(width: 22, height: 16)
        let menu = NSMenu()
        menu.addItem(withTitle: "Quit MoveB", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu

        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)

        windowMode = WindowMode()
        hotKey = HotKey(keyCode: KeyCode.m, modifiers: .command) { [weak self] in
            self?.windowMode.toggle()
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
