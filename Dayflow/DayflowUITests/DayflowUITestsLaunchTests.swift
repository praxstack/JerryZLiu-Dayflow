//
//  DayflowUITestsLaunchTests.swift
//  DayflowUITests
//

import XCTest

final class DayflowUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        throw XCTSkip("Template launch test — screen-recording app needs a real UI scenario before CI.")
    }
}
