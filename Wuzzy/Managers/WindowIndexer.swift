import Cocoa
import Foundation

final class WindowIndexer {
    private let queue = DispatchQueue(label: "com.brycesmith.wuzzy.windowindexer", qos: .userInitiated)
    private var timer: DispatchSourceTimer?
    private var cachedWindows: [WindowInfo] = []
    private let titleResolver = AccessibilityWindowTitleResolver()

    var onChange: (([WindowInfo]) -> Void)?
    var refreshInterval: TimeInterval = 0.4

    func start() {
        timer?.cancel()
        let newTimer = DispatchSource.makeTimerSource(queue: queue)
        newTimer.schedule(deadline: .now(), repeating: refreshInterval)
        newTimer.setEventHandler { [weak self] in
            self?.refreshWindows()
        }
        newTimer.resume()
        timer = newTimer
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    func snapshot() -> [WindowInfo] {
        queue.sync { cachedWindows }
    }

    private func refreshWindows() {
        let windows = fetchWindows()
        cachedWindows = windows
        DispatchQueue.main.async { [weak self] in
            self?.onChange?(windows)
        }
    }

    private func fetchWindows() -> [WindowInfo] {
        let options: CGWindowListOption = [.excludeDesktopElements, .optionOnScreenOnly]
        guard let array = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return []
        }

        let now = Date()
        let blacklistLayers: Set<Int> = [
            Int(CGWindowLevelForKey(.desktopWindow)),
            Int(CGWindowLevelForKey(.desktopIconWindow))
        ]

        return array.compactMap { dict -> WindowInfo? in
            guard
                let ownerName = dict[kCGWindowOwnerName as String] as? String,
                let windowNumber = dict[kCGWindowNumber as String] as? UInt32,
                let ownerPID = dict[kCGWindowOwnerPID as String] as? pid_t,
                let layer = dict[kCGWindowLayer as String] as? Int,
                let bounds = dict[kCGWindowBounds as String] as? [String: Any],
                let height = bounds["Height"] as? Double
            else {
                return nil
            }

            if blacklistLayers.contains(layer) {
                return nil
            }

            let rawTitle = (dict[kCGWindowName as String] as? String) ?? ""
            let resolvedTitle = rawTitle.isEmpty ? (titleResolver.resolvedTitle(for: CGWindowID(windowNumber),
                                                                                ownerPID: ownerPID) ?? "") : rawTitle
            let finalTitle = resolvedTitle.isEmpty ? "Untitled" : resolvedTitle

            let isOnscreen = (dict[kCGWindowAlpha as String] as? Double ?? 0) > 0

            return WindowInfo(id: CGWindowID(windowNumber),
                              applicationName: ownerName,
                              windowTitle: finalTitle,
                              ownerPID: ownerPID,
                              layer: layer,
                              isOnscreen: isOnscreen,
                              lastUpdated: now)
        }
    }
}
