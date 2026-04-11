import AppKit
import CoreGraphics
import SwiftUI

@MainActor
final class WindowThemeController: NSObject {
    private weak var window: NSWindow?
    private weak var themeModel: ClockThemeModel?
    private var timer: Timer?
    private var lastMode: ClockThemeMode?
    private var hasRequestedCaptureAccess = false
    private var hasPresentedPermissionHelp = false

    private let samplingInterval: TimeInterval = 2.5
    private let darkThreshold: CGFloat = 0.52

    init(window: NSWindow, themeModel: ClockThemeModel) {
        self.window = window
        self.themeModel = themeModel
    }

    func start() {
        stop()
        requestRefresh()

        timer = Timer.scheduledTimer(
            timeInterval: samplingInterval,
            target: self,
            selector: #selector(handleTimerTick),
            userInfo: nil,
            repeats: true
        )
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func requestRefresh() {
        refreshTheme()
    }

    @objc
    private func handleTimerTick() {
        refreshTheme()
    }

    private func refreshTheme() {
        guard let window else { return }

        let mode = sampledMode(below: window) ?? .followSystem
        guard mode != lastMode else { return }

        lastMode = mode
        apply(mode: mode, to: window)
    }

    private func apply(mode: ClockThemeMode, to window: NSWindow) {
        themeModel?.mode = mode

        switch mode {
        case .followSystem:
            window.appearance = nil
        case .light:
            window.appearance = NSAppearance(named: .aqua)
        case .dark:
            window.appearance = NSAppearance(named: .darkAqua)
        }
    }

    private func sampledMode(below window: NSWindow) -> ClockThemeMode? {
        guard CGPreflightScreenCaptureAccess() else {
            requestCaptureAccessIfNeeded()
            return nil
        }

        let sampleRect = sampleRect(for: window)
        guard sampleRect.width > 2, sampleRect.height > 2 else { return nil }

        let image = CGWindowListCreateImage(
            sampleRect,
            [.optionOnScreenBelowWindow],
            CGWindowID(window.windowNumber),
            [.boundsIgnoreFraming, .bestResolution]
        )

        guard let image else { return nil }
        guard let brightness = averageLuminance(in: image) else { return nil }

        return brightness < darkThreshold ? .dark : .light
    }

    private func requestCaptureAccessIfNeeded() {
        guard !hasRequestedCaptureAccess else { return }
        hasRequestedCaptureAccess = true

        let granted = CGRequestScreenCaptureAccess()
        if granted {
            requestRefresh()
        } else {
            presentPermissionHelpIfNeeded()
        }
    }

    private func presentPermissionHelpIfNeeded() {
        guard !hasPresentedPermissionHelp else { return }
        hasPresentedPermissionHelp = true

        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Allow Screen Recording for automatic theme matching"
        alert.informativeText = "FloatingClockMac needs Screen Recording permission to detect whether the content behind the clock is light or dark. Without it, the app can only follow the system appearance. After enabling the permission, reopen the app or use Refresh Theme from the menu bar icon."
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Not Now")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            Self.openScreenRecordingSettings()
        }
    }

    static func openScreenRecordingSettings() {
        let workspace = NSWorkspace.shared

        if let deepLink = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"),
           workspace.open(deepLink) {
            return
        }

        if let fallback = URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension") {
            _ = workspace.open(fallback)
        }
    }

    private func sampleRect(for window: NSWindow) -> CGRect {
        let frame = window.frame
        let insetX = max(24, frame.width * 0.18)
        let insetY = max(20, frame.height * 0.22)

        return frame.insetBy(dx: insetX, dy: insetY)
    }

    private func averageLuminance(in image: CGImage) -> CGFloat? {
        guard let provider = image.dataProvider, let data = provider.data else {
            return nil
        }

        let bytes = CFDataGetBytePtr(data)
        let length = CFDataGetLength(data)

        guard let bytes, length > 0 else { return nil }

        let bytesPerPixel = max(4, image.bitsPerPixel / 8)
        let step = max(bytesPerPixel * 8, bytesPerPixel)

        var total: CGFloat = 0
        var count: CGFloat = 0

        var index = 0
        while index + 2 < length {
            let r = CGFloat(bytes[index])
            let g = CGFloat(bytes[index + 1])
            let b = CGFloat(bytes[index + 2])

            total += (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0
            count += 1
            index += step
        }

        guard count > 0 else { return nil }
        return total / count
    }
}

final class ClockThemeModel: ObservableObject {
    @Published var mode: ClockThemeMode = .followSystem

    var preferredColorScheme: ColorScheme? {
        switch mode {
        case .followSystem:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

enum ClockThemeMode: Equatable {
    case followSystem
    case light
    case dark
}
