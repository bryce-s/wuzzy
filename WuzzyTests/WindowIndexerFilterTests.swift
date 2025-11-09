import XCTest
@testable import Wuzzy

final class WindowIndexerFilterTests: XCTestCase {
    func testExcludedOwnersAreFilteredOut() {
        XCTAssertFalse(WindowIndexer.shouldInclude(ownerName: "Window Server", layer: 0, title: "Cursor", height: 100, width: 200))
        XCTAssertFalse(WindowIndexer.shouldInclude(ownerName: "Notification Center", layer: 0, title: "Now Playing", height: 100, width: 200))
        XCTAssertFalse(WindowIndexer.shouldInclude(ownerName: "Wuzzy", layer: 0, title: "Overlay", height: 100, width: 200))
    }

    func testAllowsStandardWindow() {
        XCTAssertTrue(WindowIndexer.shouldInclude(ownerName: "Safari", layer: 0, title: "Documentation", height: 480, width: 640))
    }

    func testRejectsTinyTitlelessWindows() {
        XCTAssertFalse(WindowIndexer.shouldInclude(ownerName: "Safari", layer: 0, title: "", height: 3, width: 10))
    }

    func testRejectsTinyWindows() {
        XCTAssertFalse(WindowIndexer.shouldInclude(ownerName: "Safari", layer: 0, title: "Test", height: 10, width: 10))
        XCTAssertFalse(WindowIndexer.shouldInclude(ownerName: "Safari", layer: 0, title: "Test", height: 100, width: 30))
    }
}

