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
        return TealiumConfig(account: "tealiummobile", profile: "demo", environment: "dev")
    }

    override func setUp() {
        
    }

    override func tearDown() { }
    
    func testKeyLookupFromDataLayer() {
        let config = self.config
    
        let hostedDataLayer = HostedDataLayer(config: config, delegate: nil, diskStorage: nil) { _ in }
        
        config.hostedDataLayerKeys = [
            "product_view": "product_id",
            "category_view": "category_id",
        ]
        
        let dispatch = ViewDispatch("product_view", dataLayer: ["product_id": "abc123"])
        
        XCTAssertEqual(hostedDataLayer.getURL(for: dispatch.trackRequest)!, URL(string: "https://tags.tiqcdn.com/dle/\(config.account)/\(config.profile)/abc123.json")!)
    }
//
//    func testCacheExpiresWhenCacheSizeExceeded() {
//        let hostedDataLayer = HostedDataLayer(config: config)
//        let cache = HDLFullCache()
//        hostedDataLayer.cache = cache
//        let firstItem = cache.first!
//        let cacheItem = HDLCacheItem(...)
//        hostedDataLayer.cache.append(cacheItem)
//        XCTAssertEqual(hostedDataLayer.cache.count, TealiumValue.hdlMaxCacheSize)
//        XCTAssertEqual(hostedDataLayer.cache.last!, cacheItem)
//        XCTAssertFalse(hostedDataLayer.cache.contains(firstItem)) // first item was removed
//    }
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
//    func testShouldQueueReturnsFalseWhenDispatchDoesNotContainRequiredKeys() {
//        let dispatch = ViewDispatch("product_view", dataLayer: ["product_sku": "abc123"])
//        let hostedDataLayer = HostedDataLayer(config: config)
//        let cache = HDLFullCache()
//        hostedDataLayer.cache = cache
//        XCTAssertFalse((hostedDataLayer.shouldQueue(request: dispatch.trackRequest).0), "Should queue returned true unexpectedly")
//    }
//
//    func testShouldQueueReturnsTrueWhenDispatchContainsRequiredKeysButCachedDataLayerNotAvailable() {
//        let dispatch = ViewDispatch("product_view", dataLayer: ["product_id": "abc123"])
//        let hostedDataLayer = HostedDataLayer(config: config)
//        let cache = HDLFullCache()
//        hostedDataLayer.cache = cache
//        XCTAssertTrue((hostedDataLayer.shouldQueue(request: dispatch.trackRequest).0), "Should queue returned false unexpectedly")
//    }
//
//    func testShouldQueueReturnsFalseWhenDispatchContainsRequiredKeysAndCachedDataAvailable() {
//        let dispatch = ViewDispatch("product_view", dataLayer: ["product_id": "abc123"])
//        let hostedDataLayer = HostedDataLayer(config: config)
//        let cache = HDLFullCache()
//        hostedDataLayer.cache = cache
//        XCTAssertFalse((hostedDataLayer.shouldQueue(request: dispatch.trackRequest).0), "Should queue returned false unexpectedly")
//        // assert that data returned from shouldQueue contains expected cached data for product id abc123
//    }
    
}

class HostedDataLayerModuleDelegate: ModuleDelegate {
    func requestTrack(_ track: TealiumTrackRequest) {
        
    }
    
    func requestDequeue(reason: String) {
        
    }
    
    func processRemoteCommandRequest(_ request: TealiumRequest) {
        
    }
    
    
}
