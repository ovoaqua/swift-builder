//
//  MockURLSessionHTTPRemoteCommand.swift
//  TealiumRemoteCommandsTests-iOS
//
//  Created by Christina S on 6/4/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumCore

class MockURLSessionHTTPRemoteCommand: URLSessionProtocol {
    func tealiumDataTask(with url: URL, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        return HTTPRemoteCommandDataTask(completionHandler: completionHandler, url: url)
    }

    func tealiumDataTask(with: URLRequest, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        return HTTPRemoteCommandDataTask(completionHandler: completionHandler, url: with.url!)
    }

    func finishTealiumTasksAndInvalidate() { }
}

class HTTPRemoteCommandDataTask: URLSessionDataTaskProtocol {
    let completionHandler: DataTaskCompletion
    let url: URL
    let mockData = MockData(hello: "world")

    init(completionHandler: @escaping DataTaskCompletion,
         url: URL) {
        self.completionHandler = completionHandler
        self.url = url
    }
    func resume() {
        let urlResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)
        let encoded = try! JSONEncoder().encode(mockData)
        completionHandler(encoded, urlResponse, nil)
    }
}

struct MockData: Codable {
    var hello: String
}
