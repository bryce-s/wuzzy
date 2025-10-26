import AppKit
import Combine
import SwiftUI

final class OverlayWindowController: NSWindowController, NSWindowDelegate {
    private let viewModel: OverlayViewModel
    private let settings: SettingsViewModel
    private let focusController = OverlayFocusController()
    private let hostingController: NSHostingController<OverlayView>
    private var placementPreference: OverlayDisplayPreference
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: OverlayViewModel, settings: SettingsViewModel) {
        self.viewModel = viewModel
        self.settings = settings
        self.placementPreference = settings.windowDisplayPreference
        let contentRect = NSRect(x: 0, y: 0, width: 600, height: 460)

        let panel = NSPanel(contentRect: contentRect,
                            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
                            backing: .buffered,
                            defer: true)
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isFloatingPanel = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hidesOnDeactivate = true
        panel.level = .floating
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.animationBehavior = .utilityWindow

        let rootView = OverlayView(viewModel: viewModel, focusController: focusController) { [weak panel] in
            panel?.orderOut(nil)
        }
        hostingController = NSHostingController(rootView: rootView)
        panel.contentViewController = hostingController

        super.init(window: panel)
        panel.delegate = self

        settings.$windowDisplayPreference
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.placementPreference = newValue
            }
            .store(in: &cancellables)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func toggleOverlay() {
        if window?.isVisible == true {
            hideOverlay()
        } else {
            showOverlay()
        }
    }

    func showOverlay() {
        guard let window else { return }
        if let screen = screen(for: placementPreference) ?? NSScreen.main ?? NSScreen.screens.first {
            let frame = window.frame
            let screenFrame = screen.frame
            window.setFrame(NSRect(x: screenFrame.midX - frame.width / 2,
                                   y: screenFrame.midY - frame.height / 2,
                                   width: frame.width,
                                   height: frame.height),
                            display: true)
        }

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        viewModel.showOverlay()
        focusSearchField()
    }

    func hideOverlay() {
        window?.orderOut(nil)
        viewModel.overlayDidHide()
    }

    func focusSearchField() {
        focusController.requestFocus()
    }

    func windowDidResignKey(_ notification: Notification) {
        window?.orderOut(nil)
        viewModel.overlayDidHide()
    }
}

private extension OverlayWindowController {
    func screen(for preference: OverlayDisplayPreference) -> NSScreen? {
        switch preference {
        case .primary:
            return NSScreen.main ?? NSScreen.screens.first
        case .active:
            if let match = NSScreen.screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) }) {
                return match
            }
            return screen(for: .primary)
        case let .display(id, _):
            if let match = NSScreen.screens.first(where: { $0.displayIdentifier == id }) {
                return match
            }
            return screen(for: .primary)
        }
    }
}
