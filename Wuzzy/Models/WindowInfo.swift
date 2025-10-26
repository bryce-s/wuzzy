import Cocoa
import Foundation

struct WindowInfo: Identifiable, Hashable {
    let id: CGWindowID
    let applicationName: String
    let windowTitle: String
    let ownerPID: pid_t
    let layer: Int
    let isOnscreen: Bool
    let lastUpdated: Date

    var idString: String {
        "\(applicationName) — \(windowTitle)"
    }

    var displayName: String {
        "\(applicationName) — \(windowTitle)"
    }
}
