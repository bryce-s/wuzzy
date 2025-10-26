import XCTest
@testable import Wuzzy

final class WindowIndexerFilterTests: XCTestCase {
    func testExcludedOwnersAreFilteredOut() {
        XCTAssertFalse(WindowIndexer.shouldInclude(ownerName: "Window Server", layer: 0, title: "Cursor", height: 100))
        XCTAssertFalse(WindowIndexer.shouldInclude(ownerName: "Notification Center", layer: 0, title: "Now Playing", height: 100))
        XCTAssertFalse(WindowIndexer.shouldInclude(ownerName: "Wuzzy", layer: 0, title: "Overlay", height: 100))
    }

    func testAllowsStandardWindow() {
        XCTAssertTrue(WindowIndexer.shouldInclude(ownerName: "Safari", layer: 0, title: "Documentation", height: 480))
    }

    func testRejectsTinyTitlelessWindows() {
        XCTAssertFalse(WindowIndexer.shouldInclude(ownerName: "Safari", layer: 0, title: "", height: 3))
    }
}

