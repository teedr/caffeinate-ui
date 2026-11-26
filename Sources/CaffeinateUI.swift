import AppKit

@main
enum CaffeinateUI {
    @MainActor
    static func main() {
        let application = NSApplication.shared
        let delegate = CaffeinateApp()
        application.setActivationPolicy(.accessory)
        application.delegate = delegate
        withExtendedLifetime(delegate) { application.run() }
    }
}
