import AppKit
import ApplicationServices
import Foundation

final class WindowActivator {
    func activate(window: WindowInfo) {
        guard let app = NSRunningApplication(processIdentifier: window.ownerPID) else {
            return
        }

        let trusted = AXIsProcessTrusted()
        if !trusted {
            app.activate(options: [.activateIgnoringOtherApps])
            return
        }

        let appElement = AXUIElementCreateApplication(window.ownerPID)
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &value)

        if result == .success, let windowList = value as? [AXUIElement] {
            for axWindow in windowList {
                var numberValue: CFTypeRef?
                if AXUIElementCopyAttributeValue(axWindow, AccessibilityHelpers.windowNumberAttribute, &numberValue) == .success,
                   let number = numberValue as? Int,
                   number == Int(window.id) {
                    AXUIElementPerformAction(axWindow, kAXRaiseAction as CFString)
                    break
                }
            }
        }

        app.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
    }
}
