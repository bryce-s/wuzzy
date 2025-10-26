import AppKit
import Combine
import QuartzCore
import SwiftUI

final class OverlayWindowController: NSWindowController, NSWindowDelegate {
    private let viewModel: OverlayViewModel
    private let settings: SettingsViewModel
    private let focusController = OverlayFocusController()
    private let hostingController: NSHostingController<OverlayView>
    private var placementPreference: OverlayDisplayPreference
    private var isHidingOverlay = false
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
        panel.hasShadow = false
        panel.isReleasedWhenClosed = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.animationBehavior = .utilityWindow

        var dismissRelay: (() -> Void)?
        let rootView = OverlayView(viewModel: viewModel,
                                   focusController: focusController,
                                   settings: settings) {
            dismissRelay?()
        }
        hostingController = NSHostingController(rootView: rootView)
        panel.contentViewController = hostingController

        super.init(window: panel)
        panel.delegate = self

        dismissRelay = { [weak self] in
            self?.hideOverlay()
        }

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

        window.alphaValue = 0
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        viewModel.showOverlay()
        focusSearchField()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().alphaValue = 1
        }
    }

    func hideOverlay() {
        guard let window, !isHidingOverlay else { return }
        isHidingOverlay = true
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.12
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            window.orderOut(nil)
            window.alphaValue = 1
            self?.viewModel.overlayDidHide()
            self?.isHidingOverlay = false
        })
    }

    func focusSearchField() {
        focusController.requestFocus()
    }

    func windowDidResignKey(_ notification: Notification) {
        hideOverlay()
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
