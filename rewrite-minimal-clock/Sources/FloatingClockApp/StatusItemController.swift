import AppKit

@MainActor
final class StatusItemController: NSObject {
    private weak var appDelegate: AppDelegate?
    private let statusItem: NSStatusItem

    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        configureStatusItem()
    }

    private func configureStatusItem() {
        if let button = statusItem.button {
            if let image = NSImage(systemSymbolName: "clock", accessibilityDescription: "FloatingClockMac") {
                image.isTemplate = true
                button.image = image
            } else {
                button.title = "Clock"
            }
            button.toolTip = "FloatingClockMac"
        }

        let menu = NSMenu()
        menu.addItem(withTitle: "Show FloatingClockMac", action: #selector(showClock), keyEquivalent: "")
        menu.addItem(withTitle: "Refresh Theme", action: #selector(refreshTheme), keyEquivalent: "")
        menu.addItem(withTitle: "Screen Recording Settings", action: #selector(openScreenRecordingSettings), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit FloatingClockMac", action: #selector(quitApp), keyEquivalent: "q")
        menu.items.forEach { $0.target = self }
        statusItem.menu = menu
    }

    @objc
    private func showClock() {
        appDelegate?.showClockWindow()
    }

    @objc
    private func refreshTheme() {
        appDelegate?.refreshClockTheme()
    }

    @objc
    private func openScreenRecordingSettings() {
        appDelegate?.openScreenRecordingSettings()
    }

    @objc
    private func quitApp() {
        NSApp.terminate(nil)
    }
}
