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
    
    static var shouldRetryExpectation: XCTestExpectation!
    static var badDataExpectation: XCTestExpectation!
    
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
    func testRetryOnHTTPError() {
        HostedDataLayerTests.shouldRetryExpectation = self.expectation(description: "testRetryOnHTTPError")
        let retriever = HostedDataLayerRetriever()
        let session = MockURLSessionURLError()
        retriever.session = session
        let hostedDataLayer = HostedDataLayer(config: config, delegate: nil, diskStorage: MockHDLDiskStorageFullCache()) { _ in }
        hostedDataLayer.retriever = retriever
        let dispatch = ViewDispatch("product_view", dataLayer: ["product_id": "abc123"])
        _ = hostedDataLayer.shouldQueue(request: dispatch.trackRequest)
        self.wait(for: [HostedDataLayerTests.shouldRetryExpectation], timeout: 5.0)
        
    }
    
    func testNoRetryIfUnableToDecode() {
//        HostedDataLayerTests.shouldRetryExpectation = self.expectation(description: "testRetryOnHTTPError")
        let retriever = HostedDataLayerRetriever()
        let session = MockURLSessionBadResponse()
        retriever.session = session
        let hostedDataLayer = HostedDataLayer(config: config, delegate: nil, diskStorage: MockHDLDiskStorageFullCache()) { _ in }
        hostedDataLayer.retriever = retriever
        let dispatch = ViewDispatch("product_view", dataLayer: ["product_id": "abc123"])
        _ = hostedDataLayer.shouldQueue(request: dispatch.trackRequest)
//        self.wait(for: [HostedDataLayerTests.shouldRetryExpectation], timeout: 5.0)
        
    }
    
    
    func testNoRetryIfEmptyResponse() {
//        HostedDataLayerTests.shouldRetryExpectation = self.expectation(description: "testRetryOnHTTPError")
        let retriever = HostedDataLayerRetriever()
        let session = MockURLSessionEmptyResponse()
        retriever.session = session
        let hostedDataLayer = HostedDataLayer(config: config, delegate: nil, diskStorage: MockHDLDiskStorageFullCache()) { _ in }
        hostedDataLayer.retriever = retriever
        let dispatch = ViewDispatch("product_view", dataLayer: ["product_id": "abc123"])
        _ = hostedDataLayer.shouldQueue(request: dispatch.trackRequest)
//        self.wait(for: [HostedDataLayerTests.shouldRetryExpectation], timeout: 5.0)
        
    }
    
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
    
    func testRetrieverReturnsFailureIfBadResponse() {
        let retriever = HostedDataLayerRetriever()
        retriever.session = MockURLSessionBadResponse()
        retriever.getData(for: URL(string:"https://tags.tiqcdn.com")!) { result in
            switch result {
            case .failure(let error):
                XCTAssertEqual(error as! HostedDataLayerError, HostedDataLayerError.unableToDecodeData)
            case .success:
                XCTFail("Unexpected success")
            }
        }
    }
    
    func testRetrieverReturnsFailureIfHTTPError() {
        let retriever = HostedDataLayerRetriever()
        retriever.session = MockURLSessionURLError()
        retriever.getData(for: URL(string:"https://tags.tiqcdn.com")!) { result in
            switch result {
            case .failure(let error):
                XCTAssertNotNil(error)
            case .success:
                XCTFail("Unexpected success")
            }
        }
    }
    
    func testRetrieverReturnsSuccessWithExpectedResponse() {
        let retriever = HostedDataLayerRetriever()
        retriever.session = MockURLSessionURLSuccess()
        retriever.getData(for: URL(string:"https://tags.tiqcdn.com")!) { result in
            switch result {
            case .failure:
                XCTFail("Unexpected failure")
            case .success(let data):
                XCTAssertEqual(data["product_color"] as! String, "blue")
                
            }
        }
    }
    
    
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
    var session: URLSessionProtocol = MockURLSessionURLError()
    
    func getData(for url: URL, completion: @escaping ((Result<[String : Any], Error>) -> Void)) {
        
    }
    
}


//class MockHDLRetrieverSuccessfulRequest: HostedDataLayerRetrieverProtocol {
//    var session: URLSessionProtocol
//    
//    func getData(for url: URL, completion: @escaping ((Result<[String : Any], Error>) -> Void)) {
//
//    }
//
//}


class MockURLSessionURLError: URLSessionProtocol {

    var retries = 0
    
    func tealiumDataTask(with url: URL, completionHandler: @escaping (DataTaskResult) -> Void) -> URLSessionDataTaskProtocol {
        return DataTaskURLError(completionHandler: { data, response, error in
            self.retries += 1
            if self.retries == 5 {
                HostedDataLayerTests.shouldRetryExpectation.fulfill()
            }
            if let error = error {
                completionHandler(.failure(error))
            } else if let data = data, let response = response {
                completionHandler(.success((response as? HTTPURLResponse, data)))
            }
        }, url: url)
    }
    
    func tealiumDataTask(with url: URL, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        return DataTaskURLError(completionHandler: completionHandler, url: url)
    }

    func tealiumDataTask(with request: URLRequest, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        return DataTaskURLError(completionHandler: completionHandler, url: request.url!)
    }

    func finishTealiumTasksAndInvalidate() {
    }

}

class DataTaskURLError: URLSessionDataTaskProtocol {
    let completionHandler: DataTaskCompletion
    let url: URL
    init(completionHandler: @escaping DataTaskCompletion,
         url: URL) {
        self.completionHandler = completionHandler
        self.url = url
    }
    
    func resume() {
        let urlResponse = HTTPURLResponse(url: url, statusCode: 301, httpVersion: "1.1", headerFields: nil)
        completionHandler(nil, urlResponse, HTTPError.serverSideError(301))
    }

}


class MockURLSessionBadResponse: URLSessionProtocol {

    var retries = 0
    
    func tealiumDataTask(with url: URL, completionHandler: @escaping (DataTaskResult) -> Void) -> URLSessionDataTaskProtocol {
        return DataTaskBadResponse(completionHandler: { data, response, error in
            if self.retries > 0 {
                XCTFail("Should not retry")
            }
            if let error = error {
                completionHandler(.failure(error))
            } else if let data = data, let response = response {
                completionHandler(.success((response as? HTTPURLResponse, data)))
            }
            self.retries += 1
        }, url: url)
    }
    
    func tealiumDataTask(with url: URL, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        return DataTaskBadResponse(completionHandler: completionHandler, url: url)
    }

    func tealiumDataTask(with request: URLRequest, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        return DataTaskBadResponse(completionHandler: completionHandler, url: request.url!)
    }

    func finishTealiumTasksAndInvalidate() {
    }

}

class DataTaskBadResponse: URLSessionDataTaskProtocol {
    let data = "//\n".data(using: .utf8)
    let completionHandler: DataTaskCompletion
    let url: URL
    init(completionHandler: @escaping DataTaskCompletion,
         url: URL) {
        self.completionHandler = completionHandler
        self.url = url
    }
    
    func resume() {
        let urlResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)
        completionHandler(data, urlResponse, nil)
    }

}



class MockURLSessionURLSuccess: URLSessionProtocol {
    func tealiumDataTask(with url: URL, completionHandler: @escaping (DataTaskResult) -> Void) -> URLSessionDataTaskProtocol {
        return DataTaskURLSuccess(completionHandler: { data, response, error in
            if let error = error {
                completionHandler(.failure(error))
            } else if let data = data, let response = response {
                completionHandler(.success((response as? HTTPURLResponse, data)))
            }
        }, url: url)
    }
    
    func tealiumDataTask(with url: URL, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        return DataTaskURLSuccess(completionHandler: completionHandler, url: url)
    }

    func tealiumDataTask(with request: URLRequest, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        return DataTaskURLSuccess(completionHandler: completionHandler, url: request.url!)
    }

    func finishTealiumTasksAndInvalidate() {
    }

}

class DataTaskURLSuccess: URLSessionDataTaskProtocol {
    let data = """
    {
        "product_color": "blue",
        "product_category": "shorts",
        "product_price": 19.99
    }
    """.data(using: .utf8)
    let completionHandler: DataTaskCompletion
    let url: URL
    init(completionHandler: @escaping DataTaskCompletion,
         url: URL) {
        self.completionHandler = completionHandler
        self.url = url
    }
    
    func resume() {
        let urlResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)
        completionHandler(data, urlResponse, nil)
    }

}


class MockURLSessionEmptyResponse: URLSessionProtocol {
    var retries = 0
    func tealiumDataTask(with url: URL, completionHandler: @escaping (DataTaskResult) -> Void) -> URLSessionDataTaskProtocol {
        return DataTaskEmptyResponse(completionHandler: { data, response, error in
            if self.retries > 0 {
                XCTFail("Should not retry on empty response")
            }
            if let error = error {
                completionHandler(.failure(error))
            } else if let response = response {
                completionHandler(.success((response as? HTTPURLResponse, data)))
            }
            self.retries += 1
        }, url: url)
    }
    
    func tealiumDataTask(with url: URL, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        return DataTaskEmptyResponse(completionHandler: completionHandler, url: url)
    }

    func tealiumDataTask(with request: URLRequest, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        return DataTaskEmptyResponse(completionHandler: completionHandler, url: request.url!)
    }

    func finishTealiumTasksAndInvalidate() {
    }

}

class DataTaskEmptyResponse: URLSessionDataTaskProtocol {
    let completionHandler: DataTaskCompletion
    let url: URL
    init(completionHandler: @escaping DataTaskCompletion,
         url: URL) {
        self.completionHandler = completionHandler
        self.url = url
    }
    
    func resume() {
        let urlResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)
        completionHandler(nil, urlResponse, nil)
    }

}
