//
//  TealiumCrashModuleTests.swift
//  test-swift-tests-ios-crash
//
//  Created by Jonathan Wong on 2/12/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
@testable import TealiumCrash
import XCTest

class TealiumCrashModuleTests: XCTestCase {

    var crashModule: TealiumCrashModule!
    var config: TealiumConfig!
    var mockCrashReporter: MockTealiumCrashReporter!

    override func setUp() {
        super.setUp()
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnvironment")
        crashModule = TealiumCrashModule(config: config, delegate: self, diskStorage: nil, completion: {})
        mockCrashReporter = MockTealiumCrashReporter()
    }

    override func tearDown() {
        crashModule = nil
        config = nil
        super.tearDown()
    }

    func testDataFinishesWithNoResponseIfNotEnabled() {
        crashModule.crashReporter = mockCrashReporter
        _ = crashModule.data
        XCTAssertEqual(0, mockCrashReporter.hasPendingCrashReportCalledCount)
    }

    func testDataFinishesWithNoResponseWhenNoPendingCrashReport() {
        crashModule.crashReporter = mockCrashReporter
        _ = crashModule.data
        XCTAssertEqual(0, mockCrashReporter.loadPendingCrashReportDataCalledCount)
    }

    func testDataCallsGetDataMethod() {
        crashModule.crashReporter = mockCrashReporter
        mockCrashReporter.pendingCrashReport = true
        _ = crashModule.data
        XCTAssertEqual(1, mockCrashReporter.getDataCallCount)
    }
}

extension TealiumCrashModuleTests: TealiumModuleDelegate {

    func tealiumModuleFinished(module: TealiumModule, process: TealiumRequest) {
    }

    func tealiumModuleRequests(module: TealiumModule?, process: TealiumRequest) {
    }
}

class MockTealiumCrashReporter: CrashReporterProtocol {

    var pendingCrashReport = false
    var isEnabled = false
    var hasPendingCrashReportCalledCount = 0
    var enableCallCount = 0
    var loadPendingCrashReportDataCalledCount = 0
    var purgePendingCrashReportCallCount = 0
    var getDataCallCount = 0

    func hasPendingCrashReport() -> Bool {
        hasPendingCrashReportCalledCount += 1
        return pendingCrashReport
    }

    func enable() -> Bool {
        enableCallCount += 1
        return isEnabled
    }

    func loadPendingCrashReportData() -> Data! {
        loadPendingCrashReportDataCalledCount += 1
        return Data()
    }

    func purgePendingCrashReport() -> Bool {
        purgePendingCrashReportCallCount += 1
        pendingCrashReport = false
        return pendingCrashReport
    }

    func disable() {
        purgePendingCrashReportCallCount += 1
        pendingCrashReport = false
    }

    func purgePendingCrashReport() {
        purgePendingCrashReportCallCount += 1
        pendingCrashReport = false
    }

    func getData() -> [String: Any]? {
        getDataCallCount += 1
        return ["a": "1"]
    }
}
