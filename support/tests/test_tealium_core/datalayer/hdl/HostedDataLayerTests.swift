//
//  HostedDataLayerTests.swift
//  tealium-swift
//
//  Created by Craig Rouse on 13/07/2020.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumCore
import XCTest


class HostedDataLayerTests: XCTestCase {
    
    var config: TealiumConfig {
        let config = TealiumConfig(account: "tealiummobile", profile: "demo", environment: "dev")
        config.hostedDataLayerKeys = [
            "product_view": "product_id",
            "category_view": "category_id",
        ]
        return config
    }

    var randomCacheItem: HostedDataLayerCacheItem {
        HostedDataLayerCacheItem(id: "\(Int.random(in: 0...10000))", data: ["product_name": "test"])
    }
    
    override func setUp() {
        
    }

    override func tearDown() { }
    
    func testGetURLForDispatch() {
        let config = self.config
    
        let hostedDataLayer = HostedDataLayer(config: config, delegate: nil, diskStorage: nil) { _ in }
        
        let dispatch = ViewDispatch("product_view", dataLayer: ["product_id": "abc123"])
        
        XCTAssertEqual(hostedDataLayer.getURL(for: dispatch.trackRequest)!, URL(string: "https://tags.tiqcdn.com/dle/\(config.account)/\(config.profile)/abc123.json")!)
    }

    func testCacheExpiresWhenCacheSizeExceeded() {
        let hostedDataLayer = HostedDataLayer(config: config, delegate: nil, diskStorage: MockHDLDiskStorageFullCache()) { _ in }
        let firstItem = hostedDataLayer.cache!.first!
        let cacheItem = randomCacheItem
        hostedDataLayer.cache!.append(cacheItem)
        XCTAssertEqual(hostedDataLayer.cache!.count, TealiumValue.hdlCacheSizeMax)
        XCTAssertEqual(hostedDataLayer.cache!.last!, cacheItem)
        XCTAssertFalse(hostedDataLayer.cache!.contains(firstItem)) // first item was removed
    }
//
//    func testRetryOnFailure() {
//        let expectation = self.expectation(description: "testRetryOnFailure")
//        let urlSession = HDLURLSessionFailure()
//        let hostedDataLayer = HostedDataLayer(config: config, urlSession: urlSession)
//        hostedDataLayer.requestData(for: URL(string: "https://tags.tiqcdn.com/dle/\(config.account)/\(config.profile)/abc123.json")!)
//        // expectation fulfilled in URLSession when retries is incremented and second request is made by HDL manager
//        self.wait(for: [expectation], timeout: 5.0)
//
//    }
//
//    func testTrackingCallSentWithNoDataIfMaxRetriesReached() {
//        let expectation = self.expectation(description: "testRetryOnFailure")
//        let urlSession = HDLURLSessionFailure()
//        let hostedDataLayer = HostedDataLayer(config: config, urlSession: urlSession)
//        hostedDataLayer.requestData(url: URL(string: "https://tags.tiqcdn.com/dle/\(config.account)/\(config.profile)/abc123.json")!)
//        // expectation fulfilled in ModuleDelegate when tracking call is sent successfully with no HDL data
//        self.wait(for: [expectation], timeout: 5.0)
//    }
//
    func testShouldQueueReturnsFalseWhenDispatchDoesNotContainRequiredKeys() {
        let dispatch = ViewDispatch("product_view", dataLayer: ["product_sku": "abc123"])
        let hostedDataLayer = HostedDataLayer(config: config, delegate: nil, diskStorage: MockHDLDiskStorageFullCache()) { _ in }
        XCTAssertFalse((hostedDataLayer.shouldQueue(request: dispatch.trackRequest).0), "Should queue returned true unexpectedly")
    }

    func testShouldQueueReturnsTrueWhenDispatchContainsRequiredKeysButCachedDataLayerNotAvailable() {
        let dispatch = ViewDispatch("product_view", dataLayer: ["product_id": "abc123"])
        let hostedDataLayer = HostedDataLayer(config: config, delegate: nil, diskStorage: MockHDLDiskStorageEmptyCache()) { _ in }
        XCTAssertTrue((hostedDataLayer.shouldQueue(request: dispatch.trackRequest).0), "Should queue returned false unexpectedly")
    }
//
    func testShouldQueueReturnsFalseWhenDispatchContainsRequiredKeysAndCachedDataAvailable() {
        let dispatch = ViewDispatch("product_view", dataLayer: ["product_id": "abc123"])
        let hostedDataLayer = HostedDataLayer(config: config, delegate: nil, diskStorage: MockHDLDiskStorageFullCache()) { _ in }
        hostedDataLayer.cache!.append(HostedDataLayerCacheItem(id: "abc123", data: ["product_color":"red"]))
        let shouldQueue = hostedDataLayer.shouldQueue(request: dispatch.trackRequest)
        XCTAssertFalse(shouldQueue.0, "Should queue returned true unexpectedly")
        XCTAssertEqual(shouldQueue.1 as! [String: String], ["product_color":"red"])
    }
    
    func testInvalidRequestShouldQueueReturnsFalse() {
        let dispatch = ViewDispatch("product_view", dataLayer: ["product_id": "abc123"])
        let hostedDataLayer = HostedDataLayer(config: config, delegate: nil, diskStorage: MockHDLDiskStorageFullCache()) { _ in }
        let invalidRequest = TealiumEnqueueRequest(data: dispatch.trackRequest)
        let shouldQueue = hostedDataLayer.shouldQueue(request: invalidRequest)
        XCTAssertFalse(shouldQueue.0, "Should queue returned true unexpectedly")
    }
    
    func testShouldDropAlwaysReturnsFalse() {
        let dispatch = ViewDispatch("product_view", dataLayer: ["product_id": "abc123"])
        let hostedDataLayer = HostedDataLayer(config: config, delegate: nil, diskStorage: MockHDLDiskStorageFullCache()) { _ in }
        XCTAssertFalse(hostedDataLayer.shouldDrop(request: dispatch.trackRequest), "Should drop returned true unexpectedly")
    }
    
    func testShouldPurgeAlwaysReturnsFalse() {
        let dispatch = ViewDispatch("product_view", dataLayer: ["product_id": "abc123"])
        let hostedDataLayer = HostedDataLayer(config: config, delegate: nil, diskStorage: MockHDLDiskStorageFullCache()) { _ in }
        XCTAssertFalse(hostedDataLayer.shouldPurge(request: dispatch.trackRequest), "Should purge returned true unexpectedly")
    }
    
}

class HostedDataLayerModuleDelegate: ModuleDelegate {
    func requestTrack(_ track: TealiumTrackRequest) {
        
    }
    
    func requestDequeue(reason: String) {
        
    }
    
    func processRemoteCommandRequest(_ request: TealiumRequest) {
        
    }
    
    
}

class MockHDLRetrieverFailingRequest: HostedDataLayerRetrieverProtocol {
    func getData(for url: URL, completion: @escaping ((Result<[String : Any], Error>) -> Void)) {
        
    }
    
}


class MockHDLRetrieverSuccessfulRequest: HostedDataLayerRetrieverProtocol {
    func getData(for url: URL, completion: @escaping ((Result<[String : Any], Error>) -> Void)) {
        
    }
    
}
