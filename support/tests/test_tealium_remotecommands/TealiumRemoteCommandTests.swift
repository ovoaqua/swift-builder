//
//  TealiumRemoteCommandTests.swift
//  TealiumRemoteCommandsTests-iOS
//
//  Created by Christina S on 6/4/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
@testable import TealiumRemoteCommands
import XCTest

class TealiumRemoteCommandTests: XCTestCase {

    var remoteCommand: TealiumRemoteCommand!
    // compiler automatically flips to `weak`
    // you need to manually change to strong in order for tests to pass
    weak var mockDelegate = MockRemoteCommandDelegate()
    var helper = TestTealiumHelper()

    override func setUpWithError() throws {
        remoteCommand = TealiumRemoteCommand(commandId: "test", description: "Test", completion: { _ in
            // ...
        })
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDelegateMethod() {
        let expect = expectation(description: "delegate method is executed via the complete method")

        TealiumRemoteCommandsManager.pendingResponses.value["123"] = true
        let urlString = "tealium://test?request={\"config\":{\"response_id\":\"123\"}, \"payload\":{}}"
        guard let escapedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            XCTFail("Could not encode url string: \(urlString)")
            return
        }
        guard let url = URL(string: escapedString) else {
            XCTFail("Could not create URL from string: \(urlString)")
            return
        }
        let urlRequest = URLRequest(url: url)

        guard let response = TealiumRemoteCommandResponse(request: urlRequest) else {
            return
        }
        remoteCommand.delegate = mockDelegate
        mockDelegate?.asyncExpectation = expect

        remoteCommand.completeWith(response: response)

        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let result = self.mockDelegate?.remoteCommandResult else {
                XCTFail("Expected delegate to be called")
                return
            }
            XCTAssertNotNil(result)
        }
    }

    func testSendCompletionNotification() {

        TealiumRemoteCommandsManager.pendingResponses.value["123"] = true
        let urlString = "tealium://test?request={\"config\":{\"response_id\":\"123\"}, \"payload\":{}}"
        guard let escapedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            XCTFail("Could not encode url string: \(urlString)")
            return
        }
        guard let url = URL(string: escapedString) else {
            XCTFail("Could not create URL from string: \(urlString)")
            return
        }
        let urlRequest = URLRequest(url: url)

        guard let response = TealiumRemoteCommandResponse(request: urlRequest) else {
            return
        }
        TealiumRemoteCommand.sendCompletionNotification(for: "test", response: response)
        XCTAssertNil(TealiumRemoteCommandsManager.pendingResponses.value["123"])
    }

    func testCompletionNotification() {
        let commandId = "test"
        let responseId = "123"
        let notificationName = Notification.Name(rawValue: TealiumKey.jsNotificationName)
        let expected = Notification(name: notificationName, object: remoteCommand, userInfo: [TealiumRemoteCommandsKey.jsCommand: "try { utag.mobile.remote_api.response[\'\(commandId)\'][\'\(responseId)\'](\'204\',\'{\"hello\":\"world\"}\')} catch(err){ console.error(err)}"])

        let urlString = "tealium://\(commandId)?request={\"config\":{\"response_id\":\"\(responseId)\"}, \"payload\":{\"tealium_event\": \"launch\"}}"
        guard let escapedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            XCTFail("Could not encode url string: \(urlString)")
            return
        }
        guard let url = URL(string: escapedString) else {
            XCTFail("Could not create URL from string: \(urlString)")
            return
        }
        let urlRequest = URLRequest(url: url)
        guard let response = TealiumRemoteCommandResponse(request: urlRequest) else {
            return
        }
        let dict = ["hello": "world"]
        var data: Data
        do {
            data = try JSONSerialization.data(withJSONObject: dict, options: [])
            response.data = data
        } catch {
            print(error)
        }

        var notification = TealiumRemoteCommand.completionNotification(for: commandId, response: response)
        guard let jsResultString = notification?.userInfo?[TealiumRemoteCommandsKey.jsCommand] as? String else {
            return
        }
        notification?.userInfo?[TealiumRemoteCommandsKey.jsCommand] = jsResultString
        let expectedDesc = expected.description.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "")
        let notificationDesc = notification!.description.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "")
        XCTAssertEqual(expectedDesc, notificationDesc)
    }

}
