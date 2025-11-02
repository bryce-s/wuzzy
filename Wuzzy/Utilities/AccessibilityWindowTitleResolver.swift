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
        guard result == .success, let windows = elements(from: value) else {
            return nil
        }

        for axWindow in windows {
            var numberValue: CFTypeRef?
            if AXUIElementCopyAttributeValue(axWindow,
                                             AccessibilityHelpers.windowNumberAttribute,
                                             &numberValue) == .success,
               matchesWindow(numberValue, targetID: windowNumber) {
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

    private func elements(from value: CFTypeRef?) -> [AXUIElement]? {
        guard let value else { return nil }

        if let array = value as? [AXUIElement] {
            return array
        }

        guard CFGetTypeID(value) == CFArrayGetTypeID() else {
            return nil
        }

        let cfArray = value as! CFArray
        let count = CFArrayGetCount(cfArray)
        var result: [AXUIElement] = []
        result.reserveCapacity(count)

        for index in 0..<count {
            let rawValue = CFArrayGetValueAtIndex(cfArray, index)
            let element = unsafeBitCast(rawValue, to: AXUIElement.self)
            result.append(element)
        }

        return result
    }

    private func matchesWindow(_ value: CFTypeRef?, targetID: CGWindowID) -> Bool {
        guard let value else { return false }
        if let number = value as? Int {
            return number == Int(targetID)
        }
        if let number = value as? NSNumber {
            return number.intValue == Int(targetID)
        }
        return false
    }
}
