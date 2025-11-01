import SwiftUI
import AppKit

struct OverlayThemeStyle {
    let background: Color
    let border: Color
    let borderWidth: CGFloat
    let borderShadow: Shadow?
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
    let primaryText: Color
    let secondaryText: Color
    let searchFieldBackground: Color
    let searchFieldBorder: Color
    let searchFieldPlaceholder: Color
    let highlightBackground: Color
    let highlightBorder: Color
    let highlightText: Color
    let matchUnderlineColor: NSColor
    let searchFont: NSFont
    let resultFont: Font
    let usesSpotlightSearchField: Bool

    static let macOS = OverlayThemeStyle(
        background: Color(NSColor.windowBackgroundColor).opacity(0.97),
        border: Color.black.opacity(0.08),
        borderWidth: 0,
        borderShadow: Shadow(color: Color.black.opacity(0.20), radius: 22, x: 0, y: 14),
        primaryText: Color(nsColor: NSColor.labelColor),
        secondaryText: Color(nsColor: NSColor.secondaryLabelColor),
        searchFieldBackground: Color.black.opacity(0.08),
        searchFieldBorder: Color.black.opacity(0.12),
        searchFieldPlaceholder: Color(nsColor: NSColor.placeholderTextColor),
        highlightBackground: Color(NSColor.controlAccentColor).opacity(0.22),
        highlightBorder: Color(NSColor.controlAccentColor).opacity(0.55),
        highlightText: Color(nsColor: NSColor.labelColor),
        matchUnderlineColor: NSColor.controlAccentColor,
        searchFont: NSFont.systemFont(ofSize: 20, weight: .medium),
        resultFont: .system(size: 17, weight: .regular, design: .default),
        usesSpotlightSearchField: true
    )

    static let hacker = OverlayThemeStyle(
        background: Color.black.opacity(0.88),
        border: Color.red.opacity(0.6),
        borderWidth: 1,
        borderShadow: nil,
        primaryText: Color.white,
        secondaryText: Color.gray,
        searchFieldBackground: Color.white.opacity(0.1),
        searchFieldBorder: Color.white.opacity(0.15),
        searchFieldPlaceholder: Color.white.opacity(0.35),
        highlightBackground: Color.red.opacity(0.35),
        highlightBorder: Color.red.opacity(0.7),
        highlightText: Color.white,
        matchUnderlineColor: NSColor.systemRed,
        searchFont: NSFont.monospacedSystemFont(ofSize: 18, weight: .semibold),
        resultFont: .system(size: 16, weight: .medium, design: .monospaced),
        usesSpotlightSearchField: true
    )
}

extension OverlayThemeStyle {
    var primaryTextNSColor: NSColor { primaryText.nsColor }
    var secondaryTextNSColor: NSColor { secondaryText.nsColor }
    var searchFieldPlaceholderNSColor: NSColor { searchFieldPlaceholder.nsColor }
}

extension Color {
    var nsColor: NSColor { NSColor(self) }
}

enum OverlayTheme: String, CaseIterable, Codable, Identifiable {
    case macOS
    case hacker

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .macOS: return "macOS"
        case .hacker: return "Hacker"
        }
    }

    var style: OverlayThemeStyle {
        switch self {
        case .macOS: return .macOS
        case .hacker: return .hacker
        }
    }
}

enum OverlayThemeStorage {
    private static let storageKey = "com.brycesmith.wuzzy.theme"

    static func load(from defaults: UserDefaults) -> OverlayTheme? {
        guard let raw = defaults.string(forKey: storageKey) else { return nil }
        return OverlayTheme(rawValue: raw)
    }

    static func store(theme: OverlayTheme, defaults: UserDefaults) {
        defaults.set(theme.rawValue, forKey: storageKey)
    }
}
