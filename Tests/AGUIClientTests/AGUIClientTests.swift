// AGUIClientTests.swift
// AGUISwiftTests

import XCTest
@testable import AGUIClient

final class AGUIClientTests: XCTestCase {
    func testModuleVersion() {
        XCTAssertEqual(AGUIClient.version, "0.1.0")
    }

    func testModuleExists() {
        // Verify the module can be imported and used
        XCTAssertNotNil(AGUIClient.self)
    }
}
