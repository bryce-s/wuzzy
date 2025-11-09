import Cocoa
import Foundation

final class WindowIndexer {
    private let queue = DispatchQueue(label: "com.brycesmith.wuzzy.windowindexer", qos: .userInitiated)
    private var timer: DispatchSourceTimer?
    private var cachedWindows: [WindowInfo] = []
    private let titleResolver = AccessibilityWindowTitleResolver()

    var onChange: (([WindowInfo]) -> Void)?
    var refreshInterval: TimeInterval = 0.4
    var showAllWorkspaces: Bool = false

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
        var options: CGWindowListOption = [.excludeDesktopElements]
        if !showAllWorkspaces {
            options.insert(.optionOnScreenOnly)
        }
        guard let array = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return []
        }

        let now = Date()
        return array.compactMap { dict -> WindowInfo? in
            guard
                let ownerName = dict[kCGWindowOwnerName as String] as? String,
                let windowNumber = dict[kCGWindowNumber as String] as? UInt32,
                let ownerPID = dict[kCGWindowOwnerPID as String] as? pid_t,
                let layer = dict[kCGWindowLayer as String] as? Int,
                let bounds = dict[kCGWindowBounds as String] as? [String: Any],
                let height = bounds["Height"] as? Double,
                let width = bounds["Width"] as? Double
            else {
                return nil
            }

            // Filter out invisible windows when showing all workspaces
            let alpha = (dict[kCGWindowAlpha as String] as? Double) ?? 0
            if showAllWorkspaces && alpha <= 0 {
                return nil
            }

            let rawTitle = (dict[kCGWindowName as String] as? String) ?? ""

            if !Self.shouldInclude(ownerName: ownerName, layer: layer, title: rawTitle, height: height, width: width) {
                return nil
            }

            let resolvedTitle = rawTitle.isEmpty ? (titleResolver.resolvedTitle(for: CGWindowID(windowNumber),
                                                                                ownerPID: ownerPID) ?? "") : rawTitle

            // Skip windows with no title
            if resolvedTitle.isEmpty {
                return nil
            }

            let finalTitle = resolvedTitle
            let isOnscreen = alpha > 0

            return WindowInfo(id: CGWindowID(windowNumber),
                              applicationName: ownerName,
                              windowTitle: finalTitle,
                              ownerPID: ownerPID,
                              layer: layer,
                              isOnscreen: isOnscreen,
                              lastUpdated: now)
        }
    }

    static func shouldInclude(ownerName: String, layer: Int, title: String, height: Double, width: Double) -> Bool {
        if excludedOwners.contains(ownerName) {
            return false
        }

        if bannedPrefixes.contains(where: { ownerName.hasPrefix($0) }) {
            return false
        }

        if layerSet.contains(layer) {
            return false
        }

        if title.isEmpty && height < 5 {
            return false
        }

        // Filter out tiny windows that are likely not real user windows
        if width < 50 || height < 20 {
            return false
        }

        return true
    }

    private static let excludedOwners: Set<String> = {
        var set: Set<String> = ["Window Server", "Notification Center", "Control Center"]
        if let bundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String {
            set.insert(bundleName)
        }
        set.insert("Wuzzy")
        return set
    }()

    private static let bannedPrefixes: [String] = ["WindowServer"]

    private static let layerSet: Set<Int> = [
        Int(CGWindowLevelForKey(.desktopWindow)),
        Int(CGWindowLevelForKey(.desktopIconWindow))
    ]
}
