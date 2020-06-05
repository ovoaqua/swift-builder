//
//  MockRemoteCommand.swift
//  TestHost
//
//  Created by Christina S on 6/4/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumRemoteCommands

class MockRemoteCommand: TealiumRemoteCommandProtocol {

    var commandId: String
    var remoteCommandCompletion: TealiumRemoteCommandCompletion
    weak var delegate: TealiumRemoteCommandDelegate?
    var description: String?
    var completionRunCount = 0

    init() {
        commandId = "mockCommand"
        description = "mockDescription"
        remoteCommandCompletion = { _ in
            print("stub")
        }
    }

    func completeWith(response: TealiumRemoteCommandResponseProtocol) {

    }

    static func sendCompletionNotification(for commandId: String, response: TealiumRemoteCommandResponseProtocol) {

    }

}
