import XCTest
@testable import RxMusicPlayer

final class RxMusicPlayerTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(RxMusicPlayer().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
