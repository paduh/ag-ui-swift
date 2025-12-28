import XCTest
@testable import AGUIClient

final class AGUIClientTests: XCTestCase {
    func testClientFunction() {
        let client = AGUIClient()
        let result = client.clientFunction()
        XCTAssertTrue(result.contains("AGUIClient is working"))
        XCTAssertTrue(result.contains("AGUICore is working"))
    }
}

