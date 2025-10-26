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

    static let macOS = OverlayThemeStyle(
        background: Color(NSColor.windowBackgroundColor).opacity(0.98),
        border: Color.black.opacity(0.12),
        borderWidth: 0,
        borderShadow: Shadow(color: Color.black.opacity(0.18), radius: 18, x: 0, y: 12),
        primaryText: Color.primary,
        secondaryText: Color(NSColor.secondaryLabelColor),
        searchFieldBackground: Color.white.opacity(0.95),
        searchFieldBorder: Color.black.opacity(0.08),
        searchFieldPlaceholder: Color.gray.opacity(0.6),
        highlightBackground: Color(NSColor.controlAccentColor).opacity(0.18),
        highlightBorder: Color(NSColor.controlAccentColor).opacity(0.55),
        highlightText: Color.primary,
        matchUnderlineColor: NSColor.controlAccentColor,
        searchFont: NSFont.systemFont(ofSize: 20, weight: .medium),
        resultFont: .system(size: 17, weight: .regular, design: .default)
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
        resultFont: .system(size: 16, weight: .medium, design: .monospaced)
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
