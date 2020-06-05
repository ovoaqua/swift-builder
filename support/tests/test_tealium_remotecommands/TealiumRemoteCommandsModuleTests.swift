//
//  TealiumRemoteCommandsModuleTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 3/15/17.
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
@testable import TealiumRemoteCommands
import XCTest

class TealiumRemoteCommandsModuleTests: XCTestCase {

    let helper = TestTealiumHelper()
    var config: TealiumConfig!
    var module: TealiumRemoteCommandsModule!
    var remoteCommandsManager = MockRemoteCommandsManager()
    let remoteCommand = MockRemoteCommand()

    override func setUp() {
        super.setUp()
        config = helper.getConfig()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testDisableHTTPCommandsViaConfig() {
        config.remoteHTTPCommandDisabled = true
        module = TealiumRemoteCommandsModule(config: config, delegate: self, remoteCommands: remoteCommandsManager)
        guard let remoteCommands = module.remoteCommands else {
            XCTFail("remoteCommands array should not be nil")
            return
        }

        XCTAssertTrue((remoteCommands.commands.isEmpty), "Unexpected number of reserve commands found: \(String(describing: module.remoteCommands?.commands))")
    }

    // Integration Test
    func testMockTriggerFromNotification() {
        let testExpectation = expectation(description: "triggerTest")
        config.remoteHTTPCommandDisabled = false

        module = TealiumRemoteCommandsModule(config: config, delegate: self, completion: { _ in })
        // Add remote command
        let commandId = "test"
        let remoteCommand = TealiumRemoteCommand(commandId: commandId,
                                                 description: "") { _ in
                                                    testExpectation.fulfill()
        }
        module.remoteCommands?.add(remoteCommand)

        // Send trigger
        let urlString = "tealium://\(commandId)?request={\"config\":{}, \"payload\":{}}"
        guard let escapedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            XCTFail("Could not encode url string: \(urlString)")
            return
        }
        guard let url = URL(string: escapedString) else {
            XCTFail("Could not create URL from string: \(urlString)")
            return
        }
        let urlRequest = URLRequest(url: url)
        let notification = Notification(name: Notification.Name.tagmanagement,
                                        object: nil,
                                        userInfo: [TealiumKey.tagmanagementNotification: urlRequest])
        module.remoteCommands?.triggerCommandFrom(notification: notification)

        waitForExpectations(timeout: 5.0, handler: nil)

        XCTAssertTrue(1 == 1, "Remote command completion block successfully triggered.")
    }

    func testUpdateConfig() {
        config.remoteHTTPCommandDisabled = false
        module = TealiumRemoteCommandsModule(config: config, delegate: self, completion: { _ in })
        XCTAssertEqual(module.remoteCommands?.commands.count, 1)
        var newRemoteCommand = TealiumRemoteCommand(commandId: "test", description: "test") { _ in

        }
        var newConfig = config.copy
        newConfig.addRemoteCommand(newRemoteCommand)
        var updateRequest = TealiumUpdateConfigRequest(config: newConfig)
        module.updateConfig(updateRequest)
        XCTAssertEqual(module.remoteCommands?.commands.count, 1)
        newRemoteCommand = TealiumRemoteCommand(commandId: "test2", description: "test") { _ in

        }
        newConfig.remoteCommands = nil
        newConfig = config.copy
        newConfig.addRemoteCommand(newRemoteCommand)
        updateRequest = TealiumUpdateConfigRequest(config: newConfig)
        module.updateConfig(updateRequest)
        XCTAssertEqual(module.remoteCommands?.commands.count, 1)
    }

    func testInitializeWithDefaultCommands() {
        config.remoteHTTPCommandDisabled = false
        module = TealiumRemoteCommandsModule(config: config, delegate: self, completion: { _ in })
        XCTAssertEqual(module.remoteCommands?.commands.count, 1)
    }

    func testInitializeDefaultCommandsDisabled() {
        config.remoteHTTPCommandDisabled = true
        module = TealiumRemoteCommandsModule(config: config, delegate: self, remoteCommands: remoteCommandsManager)
        XCTAssertEqual(module.remoteCommands?.commands.count, 0)
    }

}

extension TealiumRemoteCommandsModuleTests: TealiumModuleDelegate {
    func requestTrack(_ track: TealiumTrackRequest) {

    }

    func requestReleaseQueue(reason: String) {

    }
}
