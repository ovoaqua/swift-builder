//
//  SessionManager.swift
//  TealiumCore
//
//  Created by Christina S on 4/27/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation


extension EventDataManager {

    /// - Returns: `String` session id for the active session.
    public var sessionId: String? {
        get {
            persistentDataStorage?.allData[TealiumKey.sessionId] as? String
        }
        set {
            if let newValue = newValue {
                add(data: [TealiumKey.sessionId: newValue], expiration: .session)
            }
        }
    }

    /// - Returns: `Bool` `true` if the session ID should be updated
    /// and all other session data should be removed.
    public var sessionExpired: Bool {
        guard qualifiedByMultipleTracks else {
            return false
        }
        guard let lastSessionDate = storedSessionRequest else {
            return true
        }

        if abs(lastSessionDate.timeIntervalSinceNow) > minutesBetweenSessionIdentifier * 60 {
            return true
        }

        return false
    }
    
    /// Upon launch, the active session is either continued from the previous session
    /// or a new session is generated based on the if there was an existing session id,
    /// the last time the session was requested (and was there sufficient user activity since)
    /// and the date the session was last refreshed.
    public func sessionInit() {
        guard let lastSessionIdRefreshDate = storedSessionIdRefresh else {
            generateSessionId()
            lastSessionIdRefresh = Date()
            add(data: [TealiumKey.sessionId: sessionId ?? "",
                       TealiumKey.lastSessionIdRefresh: lastSessionIdRefresh!.extendedIso8601String],
                expiration: .session)
            return
        }
        
        lastSessionIdRefresh = lastSessionIdRefreshDate

        guard sessionExpired else {
            sessionId = storedSessionId
            add(data: [TealiumKey.sessionId: sessionId ?? "",
                       TealiumKey.lastSessionIdRefresh: lastSessionIdRefresh!.extendedIso8601String],
                expiration: .session)
            return
        }

        refreshSessionData(initial: initialLaunch)
        lastSessionIdRefresh = Date()
        add(data: [TealiumKey.sessionId: sessionId ?? "",
                   TealiumKey.lastSessionIdRefresh: lastSessionIdRefresh!.extendedIso8601String],
            expiration: .session)
        
        if let lastEventDate = lastSessionIdRefresh,
            let date = lastEventDate.addSeconds(secondsBetweenTrackEvents) {
            qualifiedByMultipleTracks = Date() < date
        }
        
        startNewSession(with: self.sessionStarter)
    }
    
    /// Checks the last time the session id was refreshed and if the seconds between track events
    /// was qualified by the seconds between track events interval (default is 30 seconds). If
    /// qualified, and the previous session has expired, a new session is generated
    public func sessionUpdate() {
        let current = Date()
        if let lastEventDate = lastSessionIdRefresh,
            let date = lastEventDate.addSeconds(secondsBetweenTrackEvents) {
            qualifiedByMultipleTracks = Date() < date
        }

        if sessionExpired {
            refreshSessionData(initial: initialLaunch)
            startNewSession(with: sessionStarter)
        }
        lastSessionIdRefresh = current
        add(data: [TealiumKey.sessionId: sessionId ?? "",
            TealiumKey.lastSessionIdRefresh: lastSessionIdRefresh!.extendedIso8601String],
            expiration: .session)
    }

    /// Retrieves the previous session id creation date.
    /// - Returns: `Date?` the previous session id was created.
    public var storedSessionIdRefresh: Date? {
        guard let lastEvent = allEventData[TealiumKey.lastSessionIdRefresh] as? String else {
            return nil
        }
        return lastEvent.dateFromISOString
    }

    /// Retrieves the previous session request date.
    /// - Returns: `Date?` the previous session was created.
    public var storedSessionRequest: Date? {
        guard let lastSession = allEventData[TealiumKey.lastSessionRequest] as? String else {
            return nil
        }
        return lastSession.dateFromISOString
    }

    /// Retrieves the stored session id.
    /// - Returns: `String?` session id.
    public var storedSessionId: String? {
        guard let sessionId = allEventData[TealiumKey.sessionId] as? String else {
            return nil
        }
        return sessionId
    }

    /// Generates a new sessionId.
    public func generateSessionId() {
        sessionId = Date().unixTimeMilliseconds
    }

    /// Removes session data and resets session.
    /// - Parameter initial: `Bool` If the current event is the initial launch.
    public func refreshSessionData(initial: Bool) {
        sessionData = [String: Any]()
        if !initial {
           generateSessionId()
        }
    }

    /// If the tag management module is enabled, a new session is started.
    /// - Parameter sessionStarter: `SessionStarterProtocol`
    public func startNewSession(with sessionStarter: SessionStarterProtocol) {
        initialLaunch = false
        guard tagManagementIsEnabled else {
            return
        }
        lastSessionRequest = Date()
        add(data: [TealiumKey.lastSessionRequest: lastSessionRequest!.extendedIso8601String],
            expiration: .forever)
        sessionStarter.sessionRequest { _ in }
    }

}
