//
//  MockRemoteCommandsManager.swift
//  TealiumRemoteCommandsTests-iOS
//
//  Created by Christina S on 6/3/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumRemoteCommands

class MockRemoteCommandsManager: TealiumRemoteCommandsManagerProtocol {
    var commands = RemoteCommandArray()

    func add(_ remoteCommand: TealiumRemoteCommandProtocol) {

    }

    func disable() {

    }

    func remove(commandWithId: String) {

    }

    func triggerCommandFrom(request: URLRequest) -> TealiumRemoteCommandsError? {
        return TealiumRemoteCommandsError.invalidScheme
    }

    func triggerCommandFrom(notification: Notification) {

    }
}
