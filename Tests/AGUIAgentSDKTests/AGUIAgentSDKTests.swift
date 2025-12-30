import XCTest
@testable import AGUIAgentSDK

final class AGUIAgentSDKTests: XCTestCase {
    func testVersion() {
        XCTAssertEqual(AGUIAgentSDK.version, "1.0.0")
    }
    
    func testInitialization() {
        let sdk = AGUIAgentSDK()
        XCTAssertNotNil(sdk)
    }
}

