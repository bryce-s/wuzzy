import AppKit
import Carbon
import Foundation

struct Hotkey: Hashable, Codable {
    var keyCode: UInt32
    var modifiers: UInt32

    init(keyCode: UInt32, modifiers: UInt32) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    init?(event: NSEvent) {
        guard let characters = event.charactersIgnoringModifiers, !characters.isEmpty else {
            return nil
        }

        let firstScalar = characters.unicodeScalars.first!.value
        guard let virtualKey = KeyCodeMapper.virtualKey(from: firstScalar) else {
            return nil
        }

        let flags = event.modifierFlags
        let carbonFlags = KeyCodeMapper.carbonFlags(from: flags)
        guard carbonFlags != 0 else { return nil }
        self.init(keyCode: virtualKey, modifiers: carbonFlags)
    }

    var displayString: String {
        let modifierSymbols = KeyCodeMapper.symbols(for: modifiers)
        let keySymbol = KeyCodeMapper.symbol(for: keyCode)
        return (modifierSymbols + [keySymbol]).joined(separator: " ")
    }

    static let defaultShortcut = Hotkey(keyCode: UInt32(kVK_ANSI_G),
                                        modifiers: KeyCodeMapper.carbonFlags(from: [.option]))
}

enum HotkeyStorage {
    private static let storageKey = "com.brycesmith.wuzzy.hotkey"

    static func load(from defaults: UserDefaults) -> Hotkey? {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(Hotkey.self, from: data) else {
            return nil
        }
        return decoded
    }

    static func store(hotkey: Hotkey, defaults: UserDefaults) {
        let data = try? JSONEncoder().encode(hotkey)
        defaults.set(data, forKey: storageKey)
    }
}
