//
//  MockEventData.swift
//  TealiumCore
//
//  Created by Christina S on 4/27/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumCore

class MockEventDataManager: EventDataManagerProtocol {
    var sessionDataBacking = [String: Any]()

    var allEventData: [String: Any] {
        get {
            ["all": "eventdata"]
        }
        set {
            self.add(data: newValue, expiration: .forever)
        }
    }

    var allSessionData: [String: Any] {
        ["all": "sessiondata"]
    }

    var minutesBetweenSessionIdentifier: TimeInterval = 1.0

    var secondsBetweenTrackEvents: TimeInterval = 1.0

    var sessionId: String? {
        get {
            "testsessionid"
        }
        set {
            self.add(data: ["sessionId": newValue!], expiration: .session)
        }
    }

    var sessionData: [String: Any] {
        get {
            ["session": "data"]
        }
        set {
            sessionDataBacking += newValue
        }
    }

    var sessionStarter: SessionStarterProtocol {
        MockTealiumSessionStarter()
    }

    var tagManagementIsEnabled: Bool = true

    func add(data: [String: Any], expiration: Expiration) {

    }

    func add(key: String, value: Any, expiration: Expiration) {

    }

    func addTrace(id: String) {

    }

    func delete(forKeys: [String]) {

    }

    func delete(forKey key: String) {

    }

    func deleteAll() {

    }

    func leaveTrace() {

    }

    func refreshSessionData() {

    }

    func sessionRefresh() {

    }

    func startNewSession(with sessionStarter: SessionStarterProtocol) {

    }

}
