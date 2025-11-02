import AppKit
import ApplicationServices
import Carbon
import Foundation

final class WindowActivator {
    func activate(window: WindowInfo) {
        guard let app = NSRunningApplication(processIdentifier: window.ownerPID) else {
            return
        }

        guard AXIsProcessTrusted() else {
            NSLog("WindowActivator: Accessibility not trusted; activating application only")
            app.activate(options: [.activateIgnoringOtherApps])
            return
        }

        let appElement = AXUIElementCreateApplication(window.ownerPID)
        guard let windowElement = resolveWindowElement(for: window, in: appElement) else {
            NSLog("WindowActivator: unable to resolve AX window id \(window.id) (\(window.displayName))")
            app.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
            return
        }

        promote(windowInfo: window, windowElement: windowElement, appElement: appElement, app: app)
    }
}

private extension WindowActivator {
    func resolveWindowElement(for window: WindowInfo, in appElement: AXUIElement) -> AXUIElement? {
        if let direct = windowElement(in: appElement,
                                      attribute: kAXWindowsAttribute as CFString,
                                      matching: window) {
            return ensureTopLevelWindow(for: direct, targetID: window.id)
        }

        if let child = searchChildren(in: appElement, target: window, depth: 0) {
            return ensureTopLevelWindow(for: child, targetID: window.id)
        }

        return nil
    }

    func windowElement(in element: AXUIElement,
                       attribute: CFString,
                       matching target: WindowInfo) -> AXUIElement? {
        guard let candidates = axElements(for: element, attribute: attribute) else {
            return nil
        }

        for candidate in candidates where candidate.matches(window: target) {
            return candidate
        }

        NSLog("WindowActivator: direct search miss for window id \(target.id) title \"\(target.windowTitle)\"")
        return nil
    }

    func searchChildren(in element: AXUIElement,
                        target: WindowInfo,
                        depth: Int) -> AXUIElement? {
        if depth > 5 {
            return nil
        }

        guard let children = axElements(for: element, attribute: kAXChildrenAttribute as CFString) else {
            NSLog("WindowActivator: AXChildren unavailable at depth \(depth) for element \(describe(element))")
            return nil
        }

        for child in children {
            if child.matches(window: target) {
                return child
            }
            if let nested = searchChildren(in: child, target: target, depth: depth + 1) {
                return nested
            }
        }

        if depth == 0 {
            NSLog("WindowActivator: child search miss for window id \(target.id)")
        }
        return nil
    }

    func ensureTopLevelWindow(for element: AXUIElement, targetID: CGWindowID) -> AXUIElement? {
        if isTopLevelWindow(element, targetID: targetID) {
            return element
        }

        if let windowAttr = resolveAttribute(for: element, attribute: kAXWindowAttribute as CFString),
           isTopLevelWindow(windowAttr, targetID: targetID) {
            return windowAttr
        }

        var current: AXUIElement? = element
        var depth = 0
        while let candidate = current, depth < 6 {
            if isTopLevelWindow(candidate, targetID: targetID) {
                return candidate
            }
            current = resolveAttribute(for: candidate, attribute: kAXParentAttribute as CFString)
            depth += 1
        }

        NSLog("WindowActivator: using matched element directly for window id \(targetID)")
        return element
    }

    func promote(windowInfo: WindowInfo,
                 windowElement: AXUIElement,
                 appElement: AXUIElement,
                 app: NSRunningApplication) {
        let cfTrue: CFBoolean = kCFBooleanTrue
        let cfFalse: CFBoolean = kCFBooleanFalse

        setAttribute(windowElement, attribute: kAXMinimizedAttribute as CFString, value: cfFalse)
        setAttribute(appElement, attribute: kAXFrontmostAttribute as CFString, value: cfTrue)
        setAttribute(appElement, attribute: kAXMainWindowAttribute as CFString, value: windowElement)
        setAttribute(appElement, attribute: kAXFocusedWindowAttribute as CFString, value: windowElement)
        setAttribute(windowElement, attribute: kAXMainAttribute as CFString, value: cfTrue)
        setAttribute(windowElement, attribute: kAXFocusedAttribute as CFString, value: cfTrue)

        let raiseResult = AXUIElementPerformAction(windowElement, kAXRaiseAction as CFString)
        if raiseResult != .success {
            NSLog("WindowActivator: kAXRaiseAction failed with error \(raiseResult.rawValue); attempting AXShow")
            let showResult = AXUIElementPerformAction(windowElement, "AXShow" as CFString)
            if showResult != .success {
                NSLog("WindowActivator: AXShow failed with error \(showResult.rawValue); attempting click fallback")
                if !performClickFallback(window: windowInfo) {
                    NSLog("WindowActivator: click fallback failed; attempting window cycle fallback")
                    runWindowCycleFallback(targetWindow: windowInfo, app: app)
                }
            }
        }

        app.activate(options: [.activateIgnoringOtherApps, .activateAllWindows])
    }

    func performClickFallback(window: WindowInfo) -> Bool {
        guard let bounds = windowBounds(for: window.id) else {
            NSLog("WindowActivator: click fallback unable to resolve bounds for window id \(window.id)")
            return false
        }

        let clickAreaHeight = max(1.0, min(bounds.height, 40.0))
        let topInset = min(12.0, clickAreaHeight / 2.0)

        let targetPoint = CGPoint(x: bounds.midX, y: bounds.origin.y + topInset)
        let quartzPoint = convertToQuartzCoordinates(topLeftPoint: targetPoint)

        let initialLocation = NSEvent.mouseLocation
        let initialQuartzPoint = CGPoint(x: initialLocation.x, y: initialLocation.y)

        guard moveCursor(to: quartzPoint) else {
            NSLog("WindowActivator: click fallback unable to move cursor to \(quartzPoint)")
            return false
        }

        let downEvent = CGEvent(mouseEventSource: nil,
                                mouseType: .leftMouseDown,
                                mouseCursorPosition: quartzPoint,
                                mouseButton: .left)
        let upEvent = CGEvent(mouseEventSource: nil,
                              mouseType: .leftMouseUp,
                              mouseCursorPosition: quartzPoint,
                              mouseButton: .left)

        downEvent?.post(tap: .cghidEventTap)
        Thread.sleep(forTimeInterval: 0.02)
        upEvent?.post(tap: .cghidEventTap)
        Thread.sleep(forTimeInterval: 0.05)

        _ = moveCursor(to: initialQuartzPoint)

        let success = activeWindowMatches(window.id)
        NSLog("WindowActivator: click fallback completed; success=\(success)")
        return success
    }

    func runWindowCycleFallback(targetWindow: WindowInfo, app: NSRunningApplication) {
        let windowIDs = enumerateWindows(for: app)
        let maxAttempts = max(12, windowIDs.count * 3)
        NSLog("WindowActivator: starting window cycle fallback for window id \(targetWindow.id); windowCount=\(windowIDs.count); maxAttempts=\(maxAttempts)")

        if activeWindowMatches(targetWindow.id) {
            NSLog("WindowActivator: window cycle fallback aborted; target already frontmost")
            return
        }

        var lastFrontID: CGWindowID?
        for attempt in 0..<maxAttempts {
            let direction: CycleDirection = (attempt % 2 == 0) ? .forward : .backward
            sendCycleKey(direction: direction)
            Thread.sleep(forTimeInterval: 0.1)

            if let front = focusedWindow() {
                if lastFrontID != front.id {
                    NSLog("WindowActivator: cycle iteration \(attempt) direction \(direction.description) surfaced window id \(front.id) title \"\(front.windowTitle)\"")
                    lastFrontID = front.id
                }

                if front.id == targetWindow.id {
                    NSLog("WindowActivator: window cycle fallback succeeded after \(attempt + 1) iterations")
                    return
                }
            } else {
                NSLog("WindowActivator: cycle iteration \(attempt) direction \(direction.description) could not determine active window")
            }
        }

        if activeWindowMatches(targetWindow.id) {
            NSLog("WindowActivator: window cycle fallback succeeded on final check")
        } else {
            NSLog("WindowActivator: window cycle fallback failed to reach window id \(targetWindow.id)")
        }
    }
}

// MARK: - Helpers

private extension WindowActivator {
    func axElements(for element: AXUIElement, attribute: CFString) -> [AXUIElement]? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute, &value)
        guard result == .success else {
            NSLog("WindowActivator: AXUIElementCopyAttributeValue failed for \(attribute) with error \(result.rawValue)")
            return nil
        }

        guard let value else { return nil }

        if let array = value as? [AXUIElement] {
            return array
        }

        guard CFGetTypeID(value) == CFArrayGetTypeID() else {
            return nil
        }

        let cfArray = value as! CFArray
        let count = CFArrayGetCount(cfArray)
        var resultArray: [AXUIElement] = []
        resultArray.reserveCapacity(count)

        for index in 0..<count {
            let rawValue = CFArrayGetValueAtIndex(cfArray, index)
            let candidate = unsafeBitCast(rawValue, to: AXUIElement.self)
            resultArray.append(candidate)
        }

        return resultArray
    }

    func resolveAttribute(for element: AXUIElement, attribute: CFString) -> AXUIElement? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success,
              let value else {
            return nil
        }

        if CFGetTypeID(value) == AXUIElementGetTypeID() {
            return unsafeBitCast(value, to: AXUIElement.self)
        }

        return nil
    }

    func isTopLevelWindow(_ element: AXUIElement, targetID: CGWindowID) -> Bool {
        guard element.matches(windowID: targetID) else {
            return false
        }

        var roleValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleValue) == .success,
              let role = roleValue as? String else {
            return false
        }

        return role == (kAXWindowRole as String)
    }

    func setAttribute(_ element: AXUIElement, attribute: CFString, value: CFTypeRef) {
        let result = AXUIElementSetAttributeValue(element, attribute, value)
        if result == .success {
            return
        }

        var isSettable = DarwinBoolean(false)
        if AXUIElementIsAttributeSettable(element, attribute, &isSettable) == .success, isSettable.boolValue {
            let retry = AXUIElementSetAttributeValue(element, attribute, value)
            if retry == .success {
                return
            }
            NSLog("WindowActivator: failed to set \(attribute as String) after retry (error \(retry.rawValue))")
        } else {
            NSLog("WindowActivator: attribute \(attribute as String) not settable (error \(result.rawValue))")
        }
    }

    func windowBounds(for windowID: CGWindowID) -> CGRect? {
        let options: CGWindowListOption = [.excludeDesktopElements, .optionOnScreenOnly]
        guard let array = CGWindowListCopyWindowInfo(options, windowID) as? [[String: Any]] else {
            return nil
        }

        for window in array {
            guard (window[kCGWindowNumber as String] as? UInt32) == windowID,
                  let boundsDict = window[kCGWindowBounds as String] as? [String: Any],
                  let x = boundsDict["X"] as? Double,
                  let y = boundsDict["Y"] as? Double,
                  let width = boundsDict["Width"] as? Double,
                  let height = boundsDict["Height"] as? Double else {
                continue
            }

            return CGRect(x: CGFloat(x), y: CGFloat(y), width: CGFloat(width), height: CGFloat(height))
        }

        return nil
    }

    func convertToQuartzCoordinates(topLeftPoint point: CGPoint) -> CGPoint {
        let screens = NSScreen.screens
        let maxY = screens.map { $0.frame.origin.y + $0.frame.size.height }.max() ?? 0
        return CGPoint(x: point.x, y: maxY - point.y)
    }

    func moveCursor(to point: CGPoint) -> Bool {
        guard let moveEvent = CGEvent(mouseEventSource: nil,
                                      mouseType: .mouseMoved,
                                      mouseCursorPosition: point,
                                      mouseButton: .left) else {
            return false
        }
        moveEvent.post(tap: .cghidEventTap)
        return true
    }

    func activeWindowMatches(_ windowID: CGWindowID) -> Bool {
        guard let active = focusedWindow() else {
            return false
        }
        return active.id == windowID
    }

    func focusedWindow() -> WindowInfo? {
        let options: CGWindowListOption = [.excludeDesktopElements]
        guard let array = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }

        for entry in array {
            guard let layer = entry[kCGWindowLayer as String] as? Int,
                  layer == 0,
                  let ownerName = entry[kCGWindowOwnerName as String] as? String,
                  let windowNumber = entry[kCGWindowNumber as String] as? UInt32,
                  let ownerPID = entry[kCGWindowOwnerPID as String] as? pid_t else {
                continue
            }

            let title = (entry[kCGWindowName as String] as? String) ?? ""
            let isOnscreen = (entry[kCGWindowAlpha as String] as? Double ?? 0) > 0

            return WindowInfo(id: CGWindowID(windowNumber),
                              applicationName: ownerName,
                              windowTitle: title,
                              ownerPID: ownerPID,
                              layer: layer,
                              isOnscreen: isOnscreen,
                              lastUpdated: Date())
        }

        return nil
    }

    func enumerateWindows(for app: NSRunningApplication) -> [CGWindowID] {
        let options: CGWindowListOption = [.excludeDesktopElements, .optionOnScreenOnly]
        guard let array = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return []
        }

        let appPID = app.processIdentifier
        return array.compactMap { window in
            if (window[kCGWindowOwnerPID as String] as? pid_t) == appPID,
               let number = window[kCGWindowNumber as String] as? UInt32 {
                return CGWindowID(number)
            }
            return nil
        }
    }

    enum CycleDirection {
        case forward
        case backward

        var description: String {
            switch self {
            case .forward:
                return "forward(⌘`)"
            case .backward:
                return "backward(⇧⌘`)"
            }
        }
    }

    func sendCycleKey(direction: CycleDirection) {
        let keyCode = UInt16(kVK_ANSI_Grave)
        guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false) else {
            NSLog("WindowActivator: unable to synthesise keyboard events for window cycle fallback")
            return
        }

        var modifiers = CGEventFlags.maskCommand
        if direction == .backward {
            modifiers.insert(.maskShift)
        }

        keyDown.flags = modifiers
        keyDown.post(tap: .cghidEventTap)

        keyUp.flags = modifiers
        keyUp.post(tap: .cghidEventTap)
    }

    func describe(_ element: AXUIElement) -> String {
        let idString = windowIDValue(for: element).map(String.init) ?? "unknown"
        let title = title(for: element) ?? "no title"
        return "id=\(idString) title=\"\(title)\""
    }

    func title(for element: AXUIElement) -> String? {
        var titleValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &titleValue) == .success else {
            return nil
        }
        return titleValue as? String
    }

    func windowIDValue(for element: AXUIElement) -> Int? {
        var numberValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element,
                                            AccessibilityHelpers.windowNumberAttribute,
                                            &numberValue) == .success else {
            return nil
        }

        if let number = numberValue as? Int {
            return number
        }
        if let number = numberValue as? NSNumber {
            return number.intValue
        }
        return nil
    }
}

private extension AXUIElement {
    func matches(window: WindowInfo) -> Bool {
        if matches(windowID: window.id) {
            return true
        }

        let targetTitle = window.windowTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !targetTitle.isEmpty else { return false }

        var titleValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(self, kAXTitleAttribute as CFString, &titleValue) == .success,
              let title = titleValue as? String else {
            return false
        }

        return title.compare(targetTitle, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
    }

    func matches(windowID: CGWindowID) -> Bool {
        var numberValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(self,
                                            AccessibilityHelpers.windowNumberAttribute,
                                            &numberValue) == .success else {
            return false
        }

        if let number = numberValue as? Int {
            return number == Int(windowID)
        }
        if let number = numberValue as? NSNumber {
            return number.intValue == Int(windowID)
        }

        return false
    }
}
