import AppKit
import SwiftUI

struct MatchedTextView: View {
    let text: String
    let matchedIndices: [Int]
    let baseColor: NSColor
    let highlightColor: NSColor

    var body: some View {
        Text(attributedText)
            .lineLimit(1)
            .truncationMode(.tail)
    }

    private var attributedText: AttributedString {
        let attributed = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: (text as NSString).length)
        attributed.addAttribute(.foregroundColor, value: baseColor, range: fullRange)

        matchedIndices.sorted().forEach { index in
            guard index < fullRange.length else { return }
            let range = NSRange(location: index, length: 1)
            attributed.addAttributes([
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .foregroundColor: highlightColor
            ], range: range)
        }

        return AttributedString(attributed)
    }
}
