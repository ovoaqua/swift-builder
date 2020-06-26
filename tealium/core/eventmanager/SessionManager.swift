//
//  SessionManager.swift
//  TealiumCore
//
//  Created by Christina S on 4/27/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public extension EventDataManager {

    /// Calculates the number of track calls within the specified `secondsBetweenTrackEvents`
    /// property that will then determine if a new session shall be generated.
    // swiftlint:disable unused_setter_value
    var numberOfTracks: Int {
        get {
            numberOfTracksBacking
        }
        set {
            let current = Date()
            if let lastTrackDate = lastTrackDate,
               config.sessionHandlingEnabled {
                if let date = lastTrackDate.addSeconds(secondsBetweenTrackEvents),
                   date > current {
                    let tracks = numberOfTracksBacking + 1
                    if tracks == 2 {
                        startNewSession(with: sessionStarter)
                    }
                } else {
                    self.lastTrackDate = Date()
                    numberOfTracksBacking = 0
                }
            }
            self.lastTrackDate = Date()
            numberOfTracksBacking += 1
        }
    }
    // swiftlint:enable unused_setter_value

    /// - Returns: `String` session id for the active session.
    var sessionId: String? {
        get {
            persistentDataStorage?.removeExpired().allData[TealiumKey.sessionId] as? String
        }
        set {
            if let newValue = newValue {
                add(data: [TealiumKey.sessionId: newValue], expiration: .session)
            }
        }
    }

    /// Removes session data, generates a new session id, and sets the trigger session request flag.
    /// - Parameter initial: `Bool` If the current event is the initial launch.
    func refreshSessionData() {
        sessionData = [String: Any]()
        sessionId = Date().unixTimeMilliseconds
        shouldTriggerSessionRequest = true
        add(key: TealiumKey.sessionId, value: sessionId!, expiration: .session)
    }

    /// Checks if the session has expired in storage, if so, refreshes the session and saves the new data.
    func sessionRefresh() {
        guard let existingSessionId = sessionId else {
            numberOfTracks = 0
            refreshSessionData()
            return
        }
        numberOfTracks += 1
        add(key: TealiumKey.sessionId, value: existingSessionId, expiration: .session)
    }

    /// If the tag management module is enabled and multiple tracks have been sent in given time, a new session is started.
    /// - Parameter sessionStarter: `SessionStarterProtocol`
    func startNewSession(with sessionStarter: SessionStarterProtocol) {
        if tagManagementIsEnabled, shouldTriggerSessionRequest {
            sessionStarter.sessionRequest { [weak self] result in
                switch result {
                case .success:
                    self?.shouldTriggerSessionRequest = false
                    self?.numberOfTracksBacking = 0
                    self?.lastTrackDate = nil
                default:
                    break
                }
            }
        }
    }

}
