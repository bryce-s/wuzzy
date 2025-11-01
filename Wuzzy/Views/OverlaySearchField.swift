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
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> SpotlightSearchField {
        let field = SpotlightSearchField(frame: .zero)
        field.delegate = context.coordinator
        field.focusRingType = .none
        field.drawsBackground = false
        field.isBordered = false
        field.applySpotlightAppearance()
        context.coordinator.configure(field)
        return field
    }

    func updateNSView(_ nsView: SpotlightSearchField, context: Context) {
        context.coordinator.parent = self
        context.coordinator.configure(nsView)

        if nsView.stringValue != text {
            nsView.stringValue = text
        }

        if context.coordinator.lastFocusTick != focusTick {
            context.coordinator.lastFocusTick = focusTick
            DispatchQueue.main.async {
                nsView.window?.makeFirstResponder(nsView)
            }
        }
    }

    final class Coordinator: NSObject, NSSearchFieldDelegate, NSTextFieldDelegate {
        var parent: OverlaySearchField
        var lastFocusTick: Int = 0

        init(parent: OverlaySearchField) {
            self.parent = parent
        }

        func configure(_ field: SpotlightSearchField) {
            field.onSubmit = parent.onSubmit
            field.onCancel = parent.onCancel
            field.onMoveUp = parent.onMoveUp
            field.onMoveDown = parent.onMoveDown
            field.textColor = parent.style.primaryTextNSColor
            field.placeholderString = parent.placeholder
            field.setFont(parent.style.searchFont)
            field.hideSearchButtons(true)
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            parent.text = field.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            switch commandSelector {
            case #selector(NSResponder.insertNewline(_:)),
                 #selector(NSResponder.insertNewlineIgnoringFieldEditor(_:)),
                 #selector(NSResponder.insertLineBreak(_:)):
                parent.onSubmit(); return true
            case #selector(NSResponder.cancelOperation(_:)):
                parent.onCancel(); return true
            case #selector(NSResponder.moveUp(_:)),
                 #selector(NSResponder.moveUpAndModifySelection(_:)):
                parent.onMoveUp(); return true
            case #selector(NSResponder.moveDown(_:)),
                 #selector(NSResponder.moveDownAndModifySelection(_:)):
                parent.onMoveDown(); return true
            default:
                return false
            }
        }
    }
}

final class SpotlightSearchField: NSSearchField {
    var onSubmit: (() -> Void)?
    var onCancel: (() -> Void)?
    var onMoveUp: (() -> Void)?
    var onMoveDown: (() -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        usesSingleLineMode = true
        sendsWholeSearchString = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applySpotlightAppearance() {
        guard let cell = cell as? NSSearchFieldCell else { return }
        cell.backgroundColor = .clear
        cell.drawsBackground = false
        cell.searchButtonCell?.isTransparent = true
        cell.cancelButtonCell?.isTransparent = true
        bezelStyle = .roundedBezel
    }

    func setFont(_ font: NSFont) {
        self.font = font
        (cell as? NSSearchFieldCell)?.font = font
    }

    func hideSearchButtons(_ hidden: Bool) {
        guard let cell = cell as? NSSearchFieldCell else { return }
        cell.searchButtonCell?.isTransparent = hidden
        cell.cancelButtonCell?.isTransparent = hidden
    }

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
