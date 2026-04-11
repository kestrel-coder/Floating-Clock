import AppKit
import SwiftUI

final class ClockWindowController: NSWindowController, NSWindowDelegate {
    private static let autosaveName = "FloatingClockMainWindow"
    private static let passiveTrafficLightAlpha: CGFloat = 0.16
    private static let activeTrafficLightAlpha: CGFloat = 0.94
    private let chromeHoverView = ChromeHoverView(frame: .zero)
    private let themeModel = ClockThemeModel()
    private var trafficLightButtons: [NSButton] = []
    private var themeController: WindowThemeController?

    init() {
        let styleMask: NSWindow.StyleMask = [
            .titled,
            .closable,
            .miniaturizable,
            .resizable,
            .fullSizeContentView
        ]

        let window = NSWindow(
            contentRect: NSRect(x: 160, y: 160, width: 360, height: 128),
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )

        super.init(window: window)
        configureWindow(window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureWindow(_ window: NSWindow) {
        window.title = "FloatingClockMac"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.acceptsMouseMovedEvents = true
        window.level = .screenSaver
        window.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary
        ]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.minSize = NSSize(width: 132, height: 42)
        window.animationBehavior = .utilityWindow
        window.setFrameAutosaveName(Self.autosaveName)
        window.toolbar = makeToolbar()
        window.toolbarStyle = .unifiedCompact
        window.delegate = self

        if #available(macOS 11.0, *) {
            window.titlebarSeparatorStyle = .none
        }

        let containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        let effectView = NSVisualEffectView()
        effectView.translatesAutoresizingMaskIntoConstraints = false
        effectView.material = .hudWindow
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        effectView.wantsLayer = true
        effectView.layer?.cornerRadius = 20
        effectView.layer?.masksToBounds = true

        let hostingView = NSHostingView(rootView: ClockView(themeModel: themeModel).ignoresSafeArea())
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(effectView)
        containerView.addSubview(hostingView)
        containerView.addSubview(chromeHoverView)
        window.contentView = containerView

        NSLayoutConstraint.activate([
            effectView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            effectView.topAnchor.constraint(equalTo: containerView.topAnchor),
            effectView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            hostingView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: containerView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            chromeHoverView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            chromeHoverView.topAnchor.constraint(equalTo: containerView.topAnchor),
            chromeHoverView.widthAnchor.constraint(equalToConstant: 104),
            chromeHoverView.heightAnchor.constraint(equalToConstant: 44)
        ])

        chromeHoverView.onHoverChange = { [weak self] isHovering in
            self?.setTrafficLightsEmphasized(isHovering)
        }

        configureTrafficLights(for: window)

        let themeController = WindowThemeController(window: window, themeModel: themeModel)
        themeController.start()
        self.themeController = themeController
    }

    private func configureTrafficLights(for window: NSWindow) {
        let buttons: [NSWindow.ButtonType] = [.closeButton, .miniaturizeButton, .zoomButton]

        for buttonType in buttons {
            guard let button = window.standardWindowButton(buttonType) else { continue }
            button.translatesAutoresizingMaskIntoConstraints = false
            button.alphaValue = Self.passiveTrafficLightAlpha
            trafficLightButtons.append(button)
        }
    }

    private func setTrafficLightsEmphasized(_ emphasized: Bool) {
        let alpha = emphasized ? Self.activeTrafficLightAlpha : Self.passiveTrafficLightAlpha

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.16
            trafficLightButtons.forEach { button in
                button.animator().alphaValue = alpha
            }
        }
    }

    private func makeToolbar() -> NSToolbar {
        let toolbar = NSToolbar(identifier: "FloatingClockToolbar")
        toolbar.showsBaselineSeparator = false
        toolbar.displayMode = .iconOnly
        toolbar.allowsUserCustomization = false
        toolbar.autosavesConfiguration = false
        return toolbar
    }

    func windowDidMove(_ notification: Notification) {
        themeController?.requestRefresh()
    }

    func windowDidResize(_ notification: Notification) {
        themeController?.requestRefresh()
    }

    func windowDidBecomeKey(_ notification: Notification) {
        themeController?.requestRefresh()
    }

    func windowDidChangeScreen(_ notification: Notification) {
        themeController?.requestRefresh()
    }

    func windowWillClose(_ notification: Notification) {
        themeController?.stop()
    }
}

private final class ChromeHoverView: NSView {
    var onHoverChange: ((Bool) -> Void)?
    private var trackingAreaRef: NSTrackingArea?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        translatesAutoresizingMaskIntoConstraints = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateTrackingAreas() {
        if let trackingAreaRef {
            removeTrackingArea(trackingAreaRef)
        }

        let trackingAreaRef = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseEnteredAndExited, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingAreaRef)
        self.trackingAreaRef = trackingAreaRef

        super.updateTrackingAreas()
    }

    override func mouseEntered(with event: NSEvent) {
        onHoverChange?(true)
    }

    override func mouseExited(with event: NSEvent) {
        onHoverChange?(false)
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }
}
