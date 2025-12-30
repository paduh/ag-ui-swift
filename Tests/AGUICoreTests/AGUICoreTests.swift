import XCTest
@testable import AGUICore

final class AGUICoreTests: XCTestCase {
    func testCoreFunction() {
        let core = AGUICore()
        XCTAssertEqual(core.coreFunction(), "AGUICore is working")
    }
    
    func testVersion() {
        XCTAssertEqual(AGUICore.version, "1.0.0")
    }
}

