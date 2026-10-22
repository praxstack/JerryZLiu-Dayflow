//
//  DayflowUITests.swift
//  DayflowUITests
//

import XCTest

final class DayflowUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it's important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        throw XCTSkip("Template UI test — add real assertions before enabling in CI.")
    }

    @MainActor
    func testLaunchPerformance() throws {
        throw XCTSkip("Template launch performance test — enable when UI coverage is ready.")
    }
}
