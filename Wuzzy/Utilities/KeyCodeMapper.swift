import AppKit
import Carbon
import Foundation

enum KeyCodeMapper {
    private static let letterKeyCodes: [UInt32: UInt32] = {
        let start = UnicodeScalar("A").value
        let codes: [UInt32] = [
            UInt32(kVK_ANSI_A), UInt32(kVK_ANSI_B), UInt32(kVK_ANSI_C), UInt32(kVK_ANSI_D),
            UInt32(kVK_ANSI_E), UInt32(kVK_ANSI_F), UInt32(kVK_ANSI_G), UInt32(kVK_ANSI_H),
            UInt32(kVK_ANSI_I), UInt32(kVK_ANSI_J), UInt32(kVK_ANSI_K), UInt32(kVK_ANSI_L),
            UInt32(kVK_ANSI_M), UInt32(kVK_ANSI_N), UInt32(kVK_ANSI_O), UInt32(kVK_ANSI_P),
            UInt32(kVK_ANSI_Q), UInt32(kVK_ANSI_R), UInt32(kVK_ANSI_S), UInt32(kVK_ANSI_T),
            UInt32(kVK_ANSI_U), UInt32(kVK_ANSI_V), UInt32(kVK_ANSI_W), UInt32(kVK_ANSI_X),
            UInt32(kVK_ANSI_Y), UInt32(kVK_ANSI_Z)
        ]
        return Dictionary(uniqueKeysWithValues: codes.enumerated().map { index, code in
            (start + UInt32(index), code)
        })
    }()

    private static let keyCodeToLetter: [UInt32: String] = {
        var lookup: [UInt32: String] = [:]
        for (scalar, code) in letterKeyCodes {
            if let char = UnicodeScalar(scalar) {
                lookup[code] = String(char)
            }
        }
        return lookup
    }()

    static func carbonFlags(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var carbonFlags: UInt32 = 0
        if flags.contains(.shift) {
            carbonFlags |= UInt32(shiftKey)
        }
        if flags.contains(.control) {
            carbonFlags |= UInt32(controlKey)
        }
        if flags.contains(.option) {
            carbonFlags |= UInt32(optionKey)
        }
        if flags.contains(.command) {
            carbonFlags |= UInt32(cmdKey)
        }
        return carbonFlags
    }

    static func virtualKey(from unicodeScalar: UInt32) -> UInt32? {
        guard let scalar = UnicodeScalar(unicodeScalar) else { return nil }
        let upperCharacter = Character(String(scalar).uppercased())
        guard let normalized = upperCharacter.unicodeScalars.first?.value else { return nil }
        if let key = letterKeyCodes[normalized] {
            return key
        }
        switch normalized {
        case UnicodeScalar("0").value: return UInt32(kVK_ANSI_0)
        case UnicodeScalar("1").value: return UInt32(kVK_ANSI_1)
        case UnicodeScalar("2").value: return UInt32(kVK_ANSI_2)
        case UnicodeScalar("3").value: return UInt32(kVK_ANSI_3)
        case UnicodeScalar("4").value: return UInt32(kVK_ANSI_4)
        case UnicodeScalar("5").value: return UInt32(kVK_ANSI_5)
        case UnicodeScalar("6").value: return UInt32(kVK_ANSI_6)
        case UnicodeScalar("7").value: return UInt32(kVK_ANSI_7)
        case UnicodeScalar("8").value: return UInt32(kVK_ANSI_8)
        case UnicodeScalar("9").value: return UInt32(kVK_ANSI_9)
        case UnicodeScalar(" ").value: return UInt32(kVK_Space)
        default:
            return nil
        }
    }

    static func symbols(for modifiers: UInt32) -> [String] {
        var parts: [String] = []
        if modifiers & UInt32(cmdKey) != 0 {
            parts.append("⌘")
        }
        if modifiers & UInt32(optionKey) != 0 {
            parts.append("⌥")
        }
        if modifiers & UInt32(shiftKey) != 0 {
            parts.append("⇧")
        }
        if modifiers & UInt32(controlKey) != 0 {
            parts.append("⌃")
        }
        return parts
    }

    static func symbol(for keyCode: UInt32) -> String {
        switch keyCode {
        case UInt32(kVK_Return): return "⏎"
        case UInt32(kVK_Space): return "␣"
        case UInt32(kVK_Escape): return "⎋"
        default:
            return letterSymbol(for: keyCode) ?? "#\(keyCode)"
        }
    }

    private static func letterSymbol(for keyCode: UInt32) -> String? {
        if let letter = keyCodeToLetter[keyCode] {
            return letter
        }
        let digitMap: [UInt32: String] = [
            UInt32(kVK_ANSI_0): "0",
            UInt32(kVK_ANSI_1): "1",
            UInt32(kVK_ANSI_2): "2",
            UInt32(kVK_ANSI_3): "3",
            UInt32(kVK_ANSI_4): "4",
            UInt32(kVK_ANSI_5): "5",
            UInt32(kVK_ANSI_6): "6",
            UInt32(kVK_ANSI_7): "7",
            UInt32(kVK_ANSI_8): "8",
            UInt32(kVK_ANSI_9): "9"
        ]
        return digitMap[keyCode]
    }
}
