import XCTest
@testable import AGUITools

final class AGUIToolsTests: XCTestCase {
    func testToolsFunction() {
        let tools = AGUITools()
        let result = tools.toolsFunction()
        XCTAssertTrue(result.contains("AGUITools is working"))
        XCTAssertTrue(result.contains("AGUICore is working"))
    }
}
