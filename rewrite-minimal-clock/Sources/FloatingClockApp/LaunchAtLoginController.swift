import Foundation
import ServiceManagement

@MainActor
final class LaunchAtLoginController {
    static let shared = LaunchAtLoginController()

    private let didConfigureKey = "FloatingClockMac.didConfigureLaunchAtLogin"

    private init() {}

    func configureIfNeeded() {
        guard #available(macOS 13.0, *) else { return }
        guard shouldManageLaunchAtLogin else { return }

        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: didConfigureKey) == false else { return }

        do {
            let service = SMAppService.mainApp
            if service.status != .enabled {
                try service.register()
            }
            defaults.set(true, forKey: didConfigureKey)
        } catch {
            NSLog("Failed to enable launch at login: \(error.localizedDescription)")
        }
    }

    private var shouldManageLaunchAtLogin: Bool {
        let bundlePath = Bundle.main.bundlePath

        guard bundlePath.hasSuffix(".app") else { return false }
        guard bundlePath.contains("/.xcode-derived/") == false else { return false }
        guard bundlePath.contains("/DerivedData/") == false else { return false }

        return true
    }
}
