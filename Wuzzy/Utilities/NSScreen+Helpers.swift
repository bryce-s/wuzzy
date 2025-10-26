import AppKit

extension NSScreen {
    var displayIdentifier: String? {
        guard let number = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return nil
        }
        return number.stringValue
    }

    var friendlyName: String {
        if #available(macOS 10.15, *) {
            return localizedName
        } else {
            return "Display"
        }
        // Consider providing more detailed fallback names if needed
    }
}

