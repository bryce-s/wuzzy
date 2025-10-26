import AppKit
import Carbon
import SwiftUI

struct OverlaySearchField: NSViewRepresentable {
    @Binding var text: String
    var focusTick: Int
    var placeholder: String
    var style: OverlayThemeStyle
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
        field.font = style.searchFont
        field.textColor = style.primaryTextNSColor
        field.placeholderAttributedString = NSAttributedString(string: placeholder,
                                                               attributes: [.foregroundColor: style.searchFieldPlaceholderNSColor])
        field.onSubmit = onSubmit
        field.onCancel = onCancel
        field.onMoveUp = onMoveUp
        field.onMoveDown = onMoveDown
        return field
    }

    func updateNSView(_ nsView: KeyCaptureTextField, context: Context) {
        context.coordinator.parent = self

        if nsView.stringValue != text {
            nsView.stringValue = text
        }

        nsView.onSubmit = onSubmit
        nsView.onCancel = onCancel
        nsView.onMoveUp = onMoveUp
        nsView.onMoveDown = onMoveDown
        nsView.font = style.searchFont
        nsView.textColor = style.primaryTextNSColor
        nsView.placeholderAttributedString = NSAttributedString(string: placeholder,
                                                                attributes: [.foregroundColor: style.searchFieldPlaceholderNSColor])

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
            guard let field = obj.object as? NSTextField else {
                return
            }
            parent?.text = field.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            guard let parent else { return false }

            switch commandSelector {
            case #selector(NSResponder.insertNewline(_:)),
                 #selector(NSResponder.insertNewlineIgnoringFieldEditor(_:)),
                 #selector(NSResponder.insertLineBreak(_:)):
                parent.onSubmit()
                return true
            case #selector(NSResponder.cancelOperation(_:)):
                parent.onCancel()
                return true
            case #selector(NSResponder.moveUp(_:)),
                 #selector(NSResponder.moveUpAndModifySelection(_:)):
                parent.onMoveUp()
                return true
            case #selector(NSResponder.moveDown(_:)),
                 #selector(NSResponder.moveDownAndModifySelection(_:)):
                parent.onMoveDown()
                return true
            default:
                return false
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
