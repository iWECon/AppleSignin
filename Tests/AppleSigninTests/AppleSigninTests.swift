import XCTest
@testable import AppleSignin

final class AppleSigninTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        
        AppleSignin.shared.request()
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
