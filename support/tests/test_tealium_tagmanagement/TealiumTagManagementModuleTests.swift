//
//  TealiumTagManagementModuleTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 12/16/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
@testable import TealiumTagManagement
import XCTest

class TealiumTagManagementModuleTests: XCTestCase {

    var delegateExpectationSuccess: XCTestExpectation?
    var delegateExpectationFail: XCTestExpectation?
    var module: TagManagementModule?
    var queueName: String?
    var config: TealiumConfig!

    override func setUp() {
        super.setUp()
        config = TealiumConfig(account: "testAccount", profile: "testProfile", environment: "testEnv")
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testDispatchTrackCreatesTrackRequest() {
        module = TagManagementModule(config: config, delegate: self, eventDataManager: MockEventDataManager(), completion: { _ in })
        let track = TealiumTrackRequest(data: ["test_track": true], completion: nil)
        module?.dispatchTrack(track, completion: { result in
            switch result {
            case .failure(let error):
                XCTFail("Something went wrong creating track request: \(error)")
            case .success:
                XCTAssertTrue(true)
            }
        })
    }

    func testDispatchTrackCreatesBatchTrackRequest() {
        module = TagManagementModule(config: config, delegate: self, eventDataManager: MockEventDataManager(), completion: { _ in })
        let track = TealiumTrackRequest(data: ["test_track": true], completion: nil)
        let batchTrack = TealiumBatchTrackRequest(trackRequests: [track, track, track], completion: nil)
        module?.dispatchTrack(batchTrack, completion: { result in
            switch result {
            case .failure(let error):
                XCTFail("Something went wrong creating batch track request: \(error)")
            case .success:
                XCTAssertTrue(true)
            }
        })
    }

    func testDynamicTrackWithError() {

        module = TagManagementModule(config: config, delegate: self, eventDataManager: MockEventDataManager(), completion: { _ in })
        module?.errorState = AtomicInteger(value: 1)
        let track = TealiumTrackRequest(data: ["test_track": true], completion: nil)
        module?.dynamicTrack(track, completion: { result in
            switch result {
            case .failure(let error):
                XCTFail("Something went wrong creating batch track request: \(error)")
            case .success:
                XCTAssertTrue(true)
            }
        })

    }

    //    func testTrack() {
    //        let collectModule = TealiumCollectModule(delegate: self)
    //        collectModule.collect = TealiumCollectPostDispatcher(dispatchURL: "https://collect.tealiumiq.com", urlSession: MockURLSession(), completion: nil)
    //        let config = testTealiumConfig
    //        collectModule.enable(TealiumEnableRequest(config: config, enableCompletion: nil))
    //        let track = TealiumTrackRequest(data: ["test_track": true], completion: nil)
    //        collectModule.track(track)
    //    }
    //
    //    func testPrepareForDispatch() {
    //        let collectModule = TealiumCollectModule(delegate: nil)
    //        let config = testTealiumConfig
    //        collectModule.enable(TealiumEnableRequest(config: config, enableCompletion: nil))
    //        let track = TealiumTrackRequest(data: [String: Any](), completion: nil)
    //        let newTrack = collectModule.prepareForDispatch(track).trackDictionary
    //        XCTAssertNotNil(newTrack[TealiumKey.account])
    //        XCTAssertNotNil(newTrack[TealiumKey.profile])
    //    }
    //
    //    func testDynamicDispatchSingleTrack() {
    //        let collectModule = TealiumCollectModule(delegate: self)
    //        collectModule.collect = TealiumCollectPostDispatcher(dispatchURL: "https://collect.tealiumiq.com", urlSession: MockURLSession(), completion: nil)
    //        let config = testTealiumConfig
    //        collectModule.enable(TealiumEnableRequest(config: config, enableCompletion: nil))
    //        let track = TealiumTrackRequest(data: ["test_track": true], completion: nil)
    //        collectModule.dynamicTrack(track)
    //    }
    //
    //    func testDynamicDispatchBatchTrack() {
    //        let collectModule = TealiumCollectModule(delegate: self)
    //        collectModule.collect = TealiumCollectPostDispatcher(dispatchURL: "https://collect.tealiumiq.com", urlSession: MockURLSession(), completion: nil)
    //        let config = testTealiumConfig
    //        collectModule.enable(TealiumEnableRequest(config: config, enableCompletion: nil))
    //        let track = TealiumTrackRequest(data: ["test_track": true], completion: nil)
    //        let batchTrack = TealiumBatchTrackRequest(trackRequests: [track, track, track], completion: nil)
    //        collectModule.dynamicTrack(batchTrack)
    //    }
    //
    //    func testOverrideCollectURL() {
    //        testTealiumConfig.collectOverrideURL = "https://collect.tealiumiq.com/vdata/i.gif?tealium_account=tealiummobile&tealium_profile=someprofile"
    //        XCTAssertTrue(testTealiumConfig.optionalData[TealiumCollectKey.overrideCollectUrl] as! String == "https://collect.tealiumiq.com/vdata/i.gif?tealium_account=tealiummobile&tealium_profile=someprofile&")
    //    }
    //
    //    func testOverrideCollectProfile() {
    //        testTealiumConfig.collectOverrideProfile = "hello"
    //        XCTAssertTrue(testTealiumConfig.optionalData[TealiumCollectKey.overrideCollectProfile] as! String == "hello")
    //    }

}

extension TealiumTagManagementModuleTests: TealiumModuleDelegate {
    func tealiumModuleFinished(module: TealiumModule, process: TealiumRequest) {
        if let process = process as? TealiumTrackRequest {
            XCTAssertEqual(process.trackDictionary["test_track"] as! Bool, true)
        } else if let process = process as? TealiumBatchTrackRequest {
            process.trackRequests.forEach {
                XCTAssertEqual($0.trackDictionary["test_track"] as! Bool, true)
            }
        }
    }

    func tealiumModuleRequests(module: TealiumModule?, process: TealiumRequest) {
        XCTFail("Should not be called")
    }

}

func currentQueueName() -> String? {
    let name = __dispatch_queue_get_label(nil)
    return String(cString: name, encoding: .utf8)
}

//extension TealiumTagManagementModuleTests: TealiumModuleDelegate {
//
//    func tealiumModuleFinished(module: TealiumModule, process: TealiumRequest) {
//        delegateExpectationSuccess?.fulfill()
//
//        queueName = currentQueueName()
//    }
//
//    func tealiumModuleRequests(module: TealiumModule?, process: TealiumRequest) {
//        delegateExpectationSuccess?.fulfill()
//
//        queueName = currentQueueName()
//    }
//
//    func tealiumModuleFinishedReport(fromModule: TealiumModule, module: TealiumModule, process: TealiumRequest) {
//        delegateExpectationSuccess?.fulfill()
//
//        queueName = currentQueueName()
//    }
//
//}
