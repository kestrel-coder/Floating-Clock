import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowController: ClockWindowController?
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        LaunchAtLoginController.shared.configureIfNeeded()

        let controller = ClockWindowController()
        controller.showWindow(self)
        controller.window?.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
        windowController = controller
        statusItemController = StatusItemController(appDelegate: self)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    @MainActor
    func showClockWindow() {
        windowController?.showAndActivate()
    }

    @MainActor
    func refreshClockTheme() {
        windowController?.requestThemeRefresh()
    }

    @MainActor
    func openScreenRecordingSettings() {
        WindowThemeController.openScreenRecordingSettings()
    }
}
