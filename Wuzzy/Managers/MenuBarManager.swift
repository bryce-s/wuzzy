import AppKit
import SwiftUI

final class MenuBarManager {
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?

    var onToggleOverlay: (() -> Void)?
    var settingsViewModel: SettingsViewModel?

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            // Use SF Symbol for the icon
            button.image = NSImage(systemSymbolName: "sparkle.magnifyingglass", accessibilityDescription: "Wuzzy")
            button.image?.isTemplate = true
        }

        setupMenu()
    }

    private func setupMenu() {
        let menu = NSMenu()

        // Show Wuzzy
        let showItem = NSMenuItem(title: "Show Wuzzy", action: #selector(showOverlay), keyEquivalent: "")
        showItem.target = self
        menu.addItem(showItem)

        menu.addItem(NSMenuItem.separator())

        // Settings
        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        // About
        let aboutItem = NSMenuItem(title: "About Wuzzy", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit Wuzzy", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    @objc private func showOverlay() {
        onToggleOverlay?()
    }

    @objc private func openSettings() {
        guard let settingsViewModel = settingsViewModel else { return }

        if let existingWindow = settingsWindow, existingWindow.isVisible {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView(viewModel: settingsViewModel)
            .frame(width: 380, height: 240)

        let hostingController = NSHostingController(rootView: settingsView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Wuzzy Settings"
        window.styleMask = [.titled, .closable]
        window.center()
        window.setFrameAutosaveName("WuzzySettingsWindow")
        window.isReleasedWhenClosed = false

        settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "About Wuzzy"
        alert.informativeText = """
        Wuzzy v0.1.0

        A fast, keyboard-driven window switcher for macOS.

        © 2025 Bryce Smith
        Licensed under MIT License

        github.com/bryce-s/wuzzy
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")

        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
