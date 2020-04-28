//
//  EventDataManagerProtocol.swift
//  TealiumSwift
//
//  Created by Christina S on 4/27/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol EventDataManagerProtocol {
    var allEventData: [String: Any] { get set }
    var allSessionData: [String: Any] { get }
    var initialLaunch: Bool { get set }
    var lastSessionIdRefresh: Date? { get set }
    var lastSessionRequest: Date? { get set }
    var minutesBetweenSessionIdentifier: TimeInterval { get set }
    var qualifiedByMultipleTracks: Bool { get set }
    var secondsBetweenTrackEvents: TimeInterval { get set }
    var sessionId: String? { get set }
    var sessionData: [String: Any] { get set }
    var sessionExpired: Bool { get }
    var sessionStarter: SessionStarterProtocol { get set }
    var tagManagementIsEnabled: Bool { get set }
    func add(data: [String: Any], expiration: Expiration)
    func add(key: String, value: Any, expiration: Expiration)
    func delete(forKeys: [String])
    func delete(forKey key: String)
    func deleteAll()
    func generateSessionId()
    func refreshSessionData(initial: Bool)
    func sessionUpdate()
    func startNewSession(with sessionStarter: SessionStarterProtocol)
}
