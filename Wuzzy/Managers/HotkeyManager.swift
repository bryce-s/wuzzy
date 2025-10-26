import AppKit
import Carbon
import Foundation

final class HotkeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var callback: (() -> Void)?
    private var currentHotkey: Hotkey?

    init() {
        installEventHandler()
    }

    deinit {
        unregister()
        if let handler = eventHandler {
            RemoveEventHandler(handler)
        }
    }

    func register(hotkey: Hotkey, handler: @escaping () -> Void) {
        unregister()
        currentHotkey = hotkey
        callback = handler

        var hotKeyID = EventHotKeyID(signature: OSType("WZZY".fourCharCodeValue),
                                     id: UInt32(1))

        let status = RegisterEventHotKey(hotkey.keyCode,
                                         hotkey.modifiers,
                                         hotKeyID,
                                         GetApplicationEventTarget(),
                                         0,
                                         &hotKeyRef)

        if status != noErr {
            NSLog("Hotkey registration failed with status \(status)")
        }
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }

    private func installEventHandler() {
        guard eventHandler == nil else { return }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        let callback: EventHandlerUPP = { (_, eventRef, userData) -> OSStatus in
            guard let userData else { return noErr }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            manager.handleHotKeyEvent(eventRef: eventRef)
            return noErr
        }

        let status = InstallEventHandler(GetApplicationEventTarget(),
                                         callback,
                                         1,
                                         &eventType,
                                         Unmanaged.passUnretained(self).toOpaque(),
                                         &eventHandler)

        if status != noErr {
            NSLog("Unable to install hotkey handler: \(status)")
        }
    }

    private func handleHotKeyEvent(eventRef: EventRef?) {
        guard let eventRef else { return }
        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(eventRef,
                                       EventParamName(kEventParamDirectObject),
                                       EventParamType(typeEventHotKeyID),
                                       nil,
                                       MemoryLayout.size(ofValue: hotKeyID),
                                       nil,
                                       &hotKeyID)

        if status == noErr && hotKeyID.signature == OSType("WZZY".fourCharCodeValue) {
            callback?()
        }
    }
}

private extension String {
    var fourCharCodeValue: FourCharCode {
        var result: UInt32 = 0
        for scalar in unicodeScalars {
            result = (result << 8) + scalar.value
        }
        return FourCharCode(result)
    }
}
