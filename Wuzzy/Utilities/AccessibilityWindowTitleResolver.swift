import ApplicationServices
import Foundation

final class AccessibilityWindowTitleResolver {
    func resolvedTitle(for windowNumber: CGWindowID, ownerPID: pid_t) -> String? {
        guard AXIsProcessTrusted() else { return nil }

        if Thread.isMainThread {
            return fetchTitle(windowNumber: windowNumber, ownerPID: ownerPID)
        } else {
            var resolved: String?
            DispatchQueue.main.sync {
                resolved = self.fetchTitle(windowNumber: windowNumber, ownerPID: ownerPID)
            }
            return resolved
        }
    }

    private func fetchTitle(windowNumber: CGWindowID, ownerPID: pid_t) -> String? {
        let appElement = AXUIElementCreateApplication(ownerPID)
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &value)
        guard result == .success, let windows = value as? [AXUIElement] else {
            return nil
        }

        for axWindow in windows {
            var numberValue: CFTypeRef?
            if AXUIElementCopyAttributeValue(axWindow, AccessibilityHelpers.windowNumberAttribute, &numberValue) == .success,
               let number = numberValue as? Int,
               number == Int(windowNumber) {
                var titleValue: CFTypeRef?
                if AXUIElementCopyAttributeValue(axWindow, kAXTitleAttribute as CFString, &titleValue) == .success,
                   let title = titleValue as? String,
                   !title.isEmpty {
                    return title
                }
            }
        }

        return nil
    }
}
