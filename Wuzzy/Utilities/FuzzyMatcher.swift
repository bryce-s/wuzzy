import CoreGraphics
import Foundation

struct FuzzyMatchResult: Identifiable {
    let window: WindowInfo
    let score: Int
    let matchedIndices: [Int]

    var id: CGWindowID { window.id }

}

final class FuzzyMatcher {
    func matches(for query: String, in windows: [WindowInfo], limit: Int = 50) -> [FuzzyMatchResult] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedQuery.isEmpty {
            return windows.prefix(limit).enumerated().map { index, window in
                FuzzyMatchResult(window: window, score: Int.max - index, matchedIndices: [])
            }
        }

        let lowerQuery = trimmedQuery.lowercased()
        let results: [FuzzyMatchResult] = windows.compactMap { window in
            let haystack = window.displayName
            guard let match = score(query: lowerQuery, in: haystack) else {
                return nil
            }
            return FuzzyMatchResult(window: window, score: match.score, matchedIndices: match.indices)
        }

        return Array(results.sorted { lhs, rhs in
            lhs.score == rhs.score ? lhs.window.lastUpdated > rhs.window.lastUpdated : lhs.score > rhs.score
        }.prefix(limit))
    }

    private func score(query: String, in candidate: String) -> (score: Int, indices: [Int])? {
        let candidateLower = candidate.lowercased()
        var positions: [Int] = []
        var score = 0
        var searchStartIndex = candidateLower.startIndex
        var previousMatchIndex: Int?

        for character in query {
            guard let foundIndex = candidateLower[searchStartIndex...].firstIndex(of: character) else {
                return nil
            }

            let distance = candidateLower.distance(from: candidateLower.startIndex, to: foundIndex)
            positions.append(distance)
            score += baseScore(for: character)

            if let previous = previousMatchIndex, distance == previous + 1 {
                score += 15 // adjacency bonus
            }

            if isWordBoundary(at: foundIndex, in: candidateLower) {
                score += 25
            }

            previousMatchIndex = distance
            searchStartIndex = candidateLower.index(after: foundIndex)
        }

        // shorter matches produce higher scores
        if let first = positions.first, let last = positions.last {
            let span = last - first + 1
            score += max(0, 30 - span)
        }

        return (score, positions)
    }

    private func baseScore(for character: Character) -> Int {
        if character.isLetter {
            return 50
        }
        if character.isNumber {
            return 40
        }
        return 25
    }

    private func isWordBoundary(at index: String.Index, in string: String) -> Bool {
        if index == string.startIndex {
            return true
        }
        let beforeIndex = string.index(before: index)
        let beforeChar = string[beforeIndex]
        return beforeChar == " " || beforeChar == "-" || beforeChar == "_"
    }
}
