import AppKit
import Carbon
import SwiftUI

struct OverlaySearchField: NSViewRepresentable {
    @Binding var text: String
    var focusTick: Int
    var placeholder: String
    var onSubmit: () -> Void
    var onCancel: () -> Void
    var onMoveUp: () -> Void
    var onMoveDown: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> KeyCaptureTextField {
        let field = KeyCaptureTextField()
        field.delegate = context.coordinator
        field.isBordered = false
        field.isBezeled = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.font = NSFont.monospacedSystemFont(ofSize: 18, weight: .semibold)
        field.textColor = .white
        field.placeholderAttributedString = NSAttributedString(string: placeholder,
                                                               attributes: [.foregroundColor: NSColor.white.withAlphaComponent(0.35)])
        field.onSubmit = onSubmit
        field.onCancel = onCancel
        field.onMoveUp = onMoveUp
        field.onMoveDown = onMoveDown
        return field
    }

    func updateNSView(_ nsView: KeyCaptureTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }

        nsView.onSubmit = onSubmit
        nsView.onCancel = onCancel
        nsView.onMoveUp = onMoveUp
        nsView.onMoveDown = onMoveDown
        nsView.placeholderAttributedString = NSAttributedString(string: placeholder,
                                                                attributes: [.foregroundColor: NSColor.white.withAlphaComponent(0.35)])

        context.coordinator.parent = self

        if context.coordinator.lastFocusTick != focusTick {
            context.coordinator.lastFocusTick = focusTick
            if let window = nsView.window {
                window.makeFirstResponder(nsView)
            } else {
                DispatchQueue.main.async {
                    nsView.window?.makeFirstResponder(nsView)
                }
            }
        }
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: OverlaySearchField?
        var lastFocusTick: Int = 0

        func controlTextDidChange(_ obj: Notification) {
            guard
                let field = obj.object as? NSTextField,
                let parent
            else {
                return
            }
            if parent.text != field.stringValue {
                parent.text = field.stringValue
            }
        }
    }
}

final class KeyCaptureTextField: NSTextField {
    var onSubmit: (() -> Void)?
    var onCancel: (() -> Void)?
    var onMoveUp: (() -> Void)?
    var onMoveDown: (() -> Void)?

    override func keyDown(with event: NSEvent) {
        switch Int(event.keyCode) {
        case kVK_Return, kVK_ANSI_KeypadEnter:
            onSubmit?()
        case kVK_Escape:
            onCancel?()
        case kVK_UpArrow:
            onMoveUp?()
        case kVK_DownArrow:
            onMoveDown?()
        default:
            super.keyDown(with: event)
        }
    }
}
