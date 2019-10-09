//
//  DispatchQueueModuleTests.swift
//  tealium-swift
//
//  Created by Craig Rouse on 01/05/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumCore
@testable import TealiumDispatchQueue
import XCTest

class TealiumDispatchQueueModuleTests: XCTestCase {

    static var releaseExpectation: XCTestExpectation?
    static var expiredDispatches: XCTestExpectation?
    var diskStorage = DispatchQueueMockDiskStorage()
    var persistentQueue: PersistentQueue!
    var delegate: TealiumModuleDelegate?
    override func setUp() {
        super.setUp()
        self.persistentQueue = PersistentQueue(diskStorage: diskStorage)
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testMinimumProtocolsReturn() {
        let expectation = self.expectation(description: "minimumProtocolsReturned")
        let helper = TestTealiumHelper()
        let module = TealiumDispatchQueueModule(delegate: nil)
        module.diskStorage = diskStorage
        helper.modulesReturnsMinimumProtocols(module: module) { success, failingProtocols in

            expectation.fulfill()
            XCTAssertTrue(success, "Not all protocols returned. Failing protocols: \(failingProtocols)")

        }

        self.waitForExpectations(timeout: 4.0, handler: nil)
    }

    func testTrack() {
        let module = TealiumDispatchQueueModule(delegate: nil)
        module.enable(TealiumEnableRequest(config: TestTealiumHelper().getConfig(), enableCompletion: nil), diskStorage: diskStorage)
        module.clearQueue()
        let trackRequest = TealiumTrackRequest(data: ["tealium_event": "hello"], completion: nil)
        module.track(trackRequest)
        XCTAssertEqual(module.persistentQueue.currentEvents, 1)
        module.track(trackRequest)
        XCTAssertEqual(module.persistentQueue.currentEvents, 2)
        // wake event should not be queued
        let wakeRequest = TealiumTrackRequest(data: ["tealium_event": "wake"], completion: nil)
        module.track(wakeRequest)
        XCTAssertEqual(module.persistentQueue.currentEvents, 2)
    }

    func testQueue() {
        let module = TealiumDispatchQueueModule(delegate: nil)
        module.enable(TealiumEnableRequest(config: TestTealiumHelper().getConfig(), enableCompletion: nil), diskStorage: diskStorage)
        let trackRequest = TealiumTrackRequest(data: ["tealium_event": "wake"], completion: nil)
        let batchTrack = TealiumBatchTrackRequest(trackRequests: [trackRequest, trackRequest], completion: nil)
        module.queue(TealiumEnqueueRequest(data: batchTrack, completion: nil))
        XCTAssertEqual(module.persistentQueue.currentEvents, 2)
    }

    func testRemoveOldDispatches() {
        TealiumDispatchQueueModuleTests.expiredDispatches = self.expectation(description: "remove old dispatches")
        let module = TealiumDispatchQueueModule(delegate: nil)
        module.isEnabled = true
        module.persistentQueue = persistentQueue
        module.removeOldDispatches()
        wait(for: [TealiumDispatchQueueModuleTests.expiredDispatches!], timeout: 5.0)
    }

    func testReleaseQueue() {
        TealiumDispatchQueueModuleTests.releaseExpectation = self.expectation(description: "release queue")
        delegate = ReleaseQueueDelegate()
        let module = TealiumDispatchQueueModule(delegate: delegate!)
        module.enable(TealiumEnableRequest(config: TestTealiumHelper().getConfig(), enableCompletion: nil), diskStorage: diskStorage)
        let trackRequest = TealiumTrackRequest(data: ["tealium_event": "wake"], completion: nil)
        let batchTrack = TealiumBatchTrackRequest(trackRequests: [trackRequest, trackRequest], completion: nil)
        module.queue(TealiumEnqueueRequest(data: batchTrack, completion: nil))
        XCTAssertEqual(module.persistentQueue.currentEvents, 2)
        module.releaseQueue()
        wait(for: [TealiumDispatchQueueModuleTests.releaseExpectation!], timeout: 5.0)
    }

    func testClearQueue() {
        let module = TealiumDispatchQueueModule(delegate: nil)
        module.enable(TealiumEnableRequest(config: TestTealiumHelper().getConfig(), enableCompletion: nil), diskStorage: diskStorage)
        module.queue(TealiumEnqueueRequest(data: TealiumTrackRequest(data: ["tealium_event": "wake"], completion: nil), completion: nil))
        XCTAssertEqual(module.persistentQueue.currentEvents, 1)
        module.clearQueue()
        XCTAssertEqual(module.persistentQueue.currentEvents, 0)
    }

    func testCanQueueRequest() {
        let module = TealiumDispatchQueueModule(delegate: nil)
        module.diskStorage = diskStorage
        XCTAssertFalse(module.canQueueRequest(TealiumTrackRequest(data: ["tealium_event": "wake"], completion: nil)))
        XCTAssertTrue(module.canQueueRequest(TealiumTrackRequest(data: ["tealium_event": "view"], completion: nil)))
        module.batchingBypassKeys = ["view"]
        XCTAssertFalse(module.canQueueRequest(TealiumTrackRequest(data: ["tealium_event": "view"], completion: nil)))
    }

}

class ReleaseQueueDelegate: TealiumModuleDelegate {
    func tealiumModuleFinished(module: TealiumModule, process: TealiumRequest) {

    }

    func tealiumModuleRequests(module: TealiumModule?, process: TealiumRequest) {
        guard let request = process as? TealiumBatchTrackRequest else {
            XCTFail()
            return
        }
        XCTAssertEqual(request.trackRequests.count, 2)
        TealiumDispatchQueueModuleTests.releaseExpectation?.fulfill()
    }

}

class PersistentQueue: TealiumPersistentDispatchQueue {
    override func removeOldDispatches(_ maxQueueSize: Int, since: Date? = nil) {
        XCTAssertNotNil(since)
        TealiumDispatchQueueModuleTests.expiredDispatches!.fulfill()
    }
}
