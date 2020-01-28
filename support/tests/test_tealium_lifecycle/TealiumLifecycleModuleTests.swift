//
//  TealiumLifecycleModuleTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 2/14/17.
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
@testable import TealiumLifecycle
import XCTest

class TealiumLifecycleModuleTests: XCTestCase {

    var expectationRequest: XCTestExpectation?
    var sleepExpectation: XCTestExpectation?
    var wakeExpectation: XCTestExpectation?
    var requestProcess: TealiumRequest?
    let helper = TestTealiumHelper()

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        expectationRequest = nil
        sleepExpectation = nil
        wakeExpectation = nil
        requestProcess = nil
        super.tearDown()
    }

    func testMinimumProtocolsReturn() {
        let expectation = self.expectation(description: "minimumProtocolsReturned")
        let helper = TestTealiumHelper()
        let module = TealiumLifecycleModule(delegate: nil)
        module.diskStorage = LifecycleMockDiskStorage()
        helper.modulesReturnsMinimumProtocols(module: module) { success, failingProtocols in

            expectation.fulfill()
            XCTAssertTrue(success, "Not all protocols returned. Failing protocols: \(failingProtocols)")

        }

        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testProcessAcceptable() {
        let lifecycleModule = TealiumLifecycleModule(delegate: nil)
        // Should only accept launch calls for first events
        XCTAssertTrue(lifecycleModule.processAcceptable(type: .launch))
        XCTAssertFalse(lifecycleModule.processAcceptable(type: .sleep))
        XCTAssertFalse(lifecycleModule.processAcceptable(type: .wake))

        lifecycleModule.lastProcess = .launch
        XCTAssertFalse(lifecycleModule.processAcceptable(type: .launch))
        XCTAssertTrue(lifecycleModule.processAcceptable(type: .sleep))
        XCTAssertFalse(lifecycleModule.processAcceptable(type: .wake))

        lifecycleModule.lastProcess = .sleep
        XCTAssertFalse(lifecycleModule.processAcceptable(type: .launch))
        XCTAssertFalse(lifecycleModule.processAcceptable(type: .sleep))
        XCTAssertTrue(lifecycleModule.processAcceptable(type: .wake))

        lifecycleModule.lastProcess = .wake
        XCTAssertFalse(lifecycleModule.processAcceptable(type: .launch))
        XCTAssertTrue(lifecycleModule.processAcceptable(type: .sleep))
        XCTAssertFalse(lifecycleModule.processAcceptable(type: .wake))
    }

    func testAllAdditionalKeysPresent() {
        expectationRequest = expectation(description: "allKeysPresent")

        let lifecycleModule = TealiumLifecycleModule(delegate: self)
        lifecycleModule.enable(TealiumEnableRequest(config: helper.getConfig(), enableCompletion: nil), diskStorage: LifecycleMockDiskStorage())
        self.waitForExpectations(timeout: 5.0, handler: nil)

        guard let request = requestProcess as? TealiumTrackRequest else {
            XCTFail("\n\nFailure: Process not a track request.\n")
            return
        }
        let returnData = request.trackDictionary

        let expectedKeys = ["tealium_event"]

        let missingKeys = TestTealiumHelper.missingKeys(fromDictionary: returnData, keys: expectedKeys)

        XCTAssertTrue(missingKeys.count == 0, "Unexpected keys missing:\(missingKeys)")
    }

    func testManualLifecycleTrackingConfigSetting() {
        expectationRequest = expectation(description: "lifecycleKeysNotPresent")

        let lifecycleModule = TealiumLifecycleModule(delegate: self)
        let config = TealiumConfig(account: "testAccount", profile: "testProfile", environment: "testEnv")
        config.lifecycleAutoTrackingEnabled = false
        lifecycleModule.enable(TealiumEnableRequest(config: config, enableCompletion: nil), diskStorage: LifecycleMockDiskStorage())

        let track = TealiumTrackRequest(data: ["tealium_event": "testEvent"])
        lifecycleModule.track(track)

        var returnData = [String: Any]()
        if let request = requestProcess as? TealiumTrackRequest {
            returnData = request.trackDictionary
        }

        let expectedMissingKeys = ["lifecycle_type", "lifecycle_isfirstlaunch"]

        let missingKeys = TestTealiumHelper.missingKeys(fromDictionary: returnData, keys: expectedMissingKeys)

        XCTAssertTrue(missingKeys.count == 2, "Unexpected keys missing:\(missingKeys)")

        self.waitForExpectations(timeout: 10.0, handler: nil)

    }

    func testManualLaunchMethodCall() {
        expectationRequest = expectation(description: "manualLaunchProducesExpectedData")

        let lifecycleModule = TealiumLifecycleModule(delegate: self)
        let config = TealiumConfig(account: "testAccount", profile: "testProfile", environment: "testEnv")
        config.lifecycleAutoTrackingEnabled = false
        lifecycleModule.enable(TealiumEnableRequest(config: config, enableCompletion: nil), diskStorage: LifecycleMockDiskStorage())

        lifecycleModule.launch(at: Date())

        var returnData = [String: Any]()
        if let request = requestProcess as? TealiumTrackRequest {
            returnData = request.trackDictionary
        }

        let expectedKeys = ["lifecycle_type", "lifecycle_isfirstlaunch"]

        let expectedValues = ["launch", "true"]

        let missingKeys = TestTealiumHelper.missingKeys(fromDictionary: returnData, keys: expectedKeys)

        XCTAssertTrue(missingKeys.count == 0, "Unexpected keys missing:\(missingKeys)")

        _ = expectedKeys.enumerated().map {
            if let value = returnData[$1] as? String {
                XCTAssertEqual(value, expectedValues[$0])
            }
        }

        self.waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testManualSleepMethodCall() {
        sleepExpectation = expectation(description: "manualSleepProducesExpectedData")

        let lifecycleModule = TealiumLifecycleModule(delegate: self)
        let config = TealiumConfig(account: "testAccount", profile: "testProfile", environment: "testEnv")
        config.lifecycleAutoTrackingEnabled = false
        lifecycleModule.enable(TealiumEnableRequest(config: config, enableCompletion: nil), diskStorage: LifecycleMockDiskStorage())

        lifecycleModule.launch(at: Date())
        lifecycleModule.sleep()

        var returnData = [String: Any]()
        if let request = requestProcess as? TealiumTrackRequest {
            returnData = request.trackDictionary
        }

        let expectedKeys = ["lifecycle_type", "lifecycle_sleepcount"]

        let expectedValues = ["sleep", "1"]

        let missingKeys = TestTealiumHelper.missingKeys(fromDictionary: returnData, keys: expectedKeys)

        XCTAssertTrue(missingKeys.count == 0, "Unexpected keys missing:\(missingKeys)")

        _ = expectedKeys.enumerated().map {
            if let value = returnData[$1] as? String {
                XCTAssertEqual(value, expectedValues[$0])
            }
        }

        self.waitForExpectations(timeout: 8.0, handler: nil)
    }

    func testManualWakeMethodCall() {
        wakeExpectation = expectation(description: "manualWakeProducesExpectedData")

        let lifecycleModule = TealiumLifecycleModule(delegate: self)
        let config = TealiumConfig(account: "testAccount", profile: "testProfile", environment: "testEnv")
        config.lifecycleAutoTrackingEnabled = false
        lifecycleModule.enable(TealiumEnableRequest(config: config, enableCompletion: nil), diskStorage: LifecycleMockDiskStorage())

        lifecycleModule.launch(at: Date())
        lifecycleModule.sleep()
        lifecycleModule.wake()

        var returnData = [String: Any]()
        if let request = requestProcess as? TealiumTrackRequest {
            returnData = request.trackDictionary
        }

        let expectedKeys = ["lifecycle_type", "lifecycle_wakecount"]

        let expectedValues = ["wake", "2"]

        let missingKeys = TestTealiumHelper.missingKeys(fromDictionary: returnData, keys: expectedKeys)

        XCTAssertTrue(missingKeys.count == 0, "Unexpected keys missing:\(missingKeys)")

        _ = expectedKeys.enumerated().map {
            if let value = returnData[$1] as? String {
                XCTAssertEqual(value, expectedValues[$0])
            }
        }

        self.waitForExpectations(timeout: 8.0, handler: nil)
    }

}

extension TealiumLifecycleModuleTests: TealiumModuleDelegate {

    func tealiumModuleFinished(module: TealiumModule, process: TealiumRequest) {
        // Lifecycle listening for all modules to finish enabling, since we're testing, mock all modules ready.
        if process as? TealiumEnableRequest != nil {
            module.handleReport(testEnableRequest)
            return
        }

        if let process = process as? TealiumTrackRequest {
                expectationRequest?.fulfill()
                requestProcess = process
        }

    }

    func tealiumModuleRequests(module: TealiumModule?, process: TealiumRequest) {
        if let process = process as? TealiumTrackRequest {
            expectationRequest?.fulfill()
            if sleepExpectation?.description == "manualSleepProducesExpectedData" && (process.trackDictionary["lifecycle_type"] as! String) == "sleep" {
                sleepExpectation?.fulfill()
            }
            if wakeExpectation?.description == "manualWakeProducesExpectedData" && (process.trackDictionary["lifecycle_type"] as! String) == "wake" {
                wakeExpectation?.fulfill()
            }
            requestProcess = process
        }
    }

}
