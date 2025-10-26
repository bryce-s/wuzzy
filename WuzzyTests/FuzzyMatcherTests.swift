import XCTest
@testable import Wuzzy

final class FuzzyMatcherTests: XCTestCase {
    func testFuzzyMatchingPrioritizesContiguousMatches() {
        let matcher = FuzzyMatcher()
        let windowA = WindowInfo(id: 1,
                                 applicationName: "Safari",
                                 windowTitle: "Wuzzy Docs",
                                 ownerPID: 111,
                                 layer: 0,
                                 isOnscreen: true,
                                 lastUpdated: Date())
        let windowB = WindowInfo(id: 2,
                                 applicationName: "Safari",
                                 windowTitle: "WZ Doc",
                                 ownerPID: 111,
                                 layer: 0,
                                 isOnscreen: true,
                                 lastUpdated: Date())

        let results = matcher.matches(for: "wz", in: [windowA, windowB], limit: 5)
        XCTAssertEqual(results.first?.window.id, 2)
    }

    func testEmptyQueryReturnsAllWindows() {
        let matcher = FuzzyMatcher()
        let now = Date()
        let window = WindowInfo(id: 3,
                                applicationName: "Terminal",
                                windowTitle: "Shell",
                                ownerPID: 42,
                                layer: 0,
                                isOnscreen: true,
                                lastUpdated: now)
        let results = matcher.matches(for: "", in: [window])
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.window.id, 3)
    }
}
