import XCTest
@testable import particle-swift

class particle-swiftTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(particle-swift().text, "Hello, World!")
    }


    static var allTests : [(String, (particle-swiftTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
