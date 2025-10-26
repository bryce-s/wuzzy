import ApplicationServices
import Foundation

final class AccessibilityAuthorizer {
    func ensureAccessibilityPrivilege() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString: true]
        let trusted = AXIsProcessTrustedWithOptions(options)
        if !trusted {
            NSLog("Accessibility permission not yet granted. Prompting user.")
        }
    }

    var isTrusted: Bool {
        AXIsProcessTrusted()
    }
}
