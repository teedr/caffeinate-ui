import AppKit

@MainActor
final class CaffeinateApp: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private struct Session {
        let process: Process
        let description: String
        let watchedApp: NSRunningApplication?
    }

    private var session: Session? {
        didSet { updateStatus() }
    }
    private var statusItem: NSStatusItem?
    private let statusLine = NSMenuItem()
    private let toggle = NSMenuItem()
    private let appsMenu = NSMenu(title: "While App Is Open")

    func applicationDidFinishLaunching(_ notification: Notification) {
        let menu = NSMenu()
        menu.autoenablesItems = false
        statusLine.isEnabled = false
        menu.addItem(statusLine)
        menu.addItem(.separator())

        toggle.target = self
        toggle.action = #selector(toggleSession)
        menu.addItem(toggle)

        let durations = NSMenu(title: "Keep Awake For")
        for (title, minutes) in [("15 Minutes", 15), ("1 Hour", 60), ("2 Hours", 120)] {
            let item = durations.addItem(withTitle: title, action: #selector(startTimer(_:)), keyEquivalent: "")
            item.target = self
            item.tag = minutes * 60
        }
        menu.addItem(withTitle: durations.title, action: nil, keyEquivalent: "").submenu = durations

        appsMenu.delegate = self
        menuNeedsUpdate(appsMenu)
        menu.addItem(withTitle: appsMenu.title, action: nil, keyEquivalent: "").submenu = appsMenu
        menu.addItem(.separator())
        let quit = menu.addItem(withTitle: "Quit Caffeinate UI", action: #selector(NSApplication.terminate(_:)),
                                keyEquivalent: "q")
        quit.target = NSApp

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.menu = menu
        statusItem = item
        updateStatus()

        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(appDidQuit(_:)),
            name: NSWorkspace.didTerminateApplicationNotification, object: nil
        )
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let runningApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && !$0.isTerminated }
            .sorted { ($0.localizedName ?? "").localizedStandardCompare($1.localizedName ?? "") == .orderedAscending }

        for app in runningApps {
            guard let name = app.localizedName else { continue }
            let item = menu.addItem(withTitle: name, action: #selector(startForApp(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = app
        }
        if menu.items.isEmpty {
            menu.addItem(withTitle: "No open apps", action: nil, keyEquivalent: "").isEnabled = false
        }
    }

    @objc private func toggleSession() {
        if session == nil {
            start(description: "Awake until stopped")
        } else {
            stop()
        }
    }

    @objc private func startTimer(_ sender: NSMenuItem) {
        let seconds = sender.tag
        let until = Date.now.addingTimeInterval(TimeInterval(seconds)).formatted(date: .omitted, time: .shortened)
        start(description: "Awake until \(until)", seconds: seconds)
    }

    @objc private func startForApp(_ sender: NSMenuItem) {
        guard let app = sender.representedObject as? NSRunningApplication,
              let name = app.localizedName, !app.isTerminated else { return }
        start(description: "Awake while \(name) is open", watchedApp: app)
    }

    @objc private func appDidQuit(_ notification: Notification) {
        guard let watched = session?.watchedApp,
              let ended = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              watched == ended else { return }
        stop()
    }

    private func start(description: String, seconds: Int? = nil, watchedApp: NSRunningApplication? = nil) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        // Watching our own PID also releases the assertion if this app is force-quit.
        var arguments = ["-i", "-w", String(ProcessInfo.processInfo.processIdentifier)]
        if let seconds { arguments += ["-t", String(seconds)] }
        process.arguments = arguments
        process.terminationHandler = { [weak self] finished in
            DispatchQueue.main.async {
                guard let self, self.session?.process === finished else { return }
                self.session = nil
            }
        }

        do {
            try process.run()
        } catch {
            NSAlert(error: error).runModal()
            return
        }
        let previous = session?.process
        session = Session(process: process, description: description, watchedApp: watchedApp)
        if let previous, previous.isRunning { previous.terminate() }
    }

    private func stop() {
        let process = session?.process
        session = nil
        if let process, process.isRunning { process.terminate() }
    }

    private func updateStatus() {
        let description = session?.description ?? "Caffeinate is off"
        let symbol = session == nil ? "cup.and.saucer" : "cup.and.saucer.fill"
        let icon = NSImage(systemSymbolName: symbol, accessibilityDescription: description)
        icon?.isTemplate = true
        statusItem?.button?.image = icon
        statusItem?.button?.toolTip = "Caffeinate UI — \(description)"
        statusItem?.button?.setAccessibilityLabel("Caffeinate UI")
        statusItem?.button?.setAccessibilityValue(description)
        statusLine.title = description
        toggle.title = session == nil ? "Keep Awake Until Stopped" : "Stop Keeping Awake"
    }

    func applicationWillTerminate(_ notification: Notification) {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        stop()
    }
}
