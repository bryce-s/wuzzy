import CoreGraphics
import Foundation

final class ScreenRecordingAuthorizer {
    func ensurePermissionPrompted() {
        if #available(macOS 10.15, *), !isAuthorized {
            CGRequestScreenCaptureAccess()
        }
    }

    var isAuthorized: Bool {
        if #available(macOS 10.15, *) {
            return CGPreflightScreenCaptureAccess()
        } else {
            return true
        }
    }
}

