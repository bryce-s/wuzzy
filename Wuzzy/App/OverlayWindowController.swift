import AppKit
import SwiftUI

final class OverlayWindowController: NSWindowController, NSWindowDelegate {
    private let viewModel: OverlayViewModel
    private let focusController = OverlayFocusController()
    private let hostingController: NSHostingController<OverlayView>

    init(viewModel: OverlayViewModel) {
        self.viewModel = viewModel
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
        if let screen = NSScreen.main {
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
