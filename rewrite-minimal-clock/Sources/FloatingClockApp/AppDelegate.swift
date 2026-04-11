import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowController: ClockWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = ClockWindowController()
        controller.showWindow(self)
        controller.window?.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
        windowController = controller
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
