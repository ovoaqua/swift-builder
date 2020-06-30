//
//  EventDataManagerProtocol.swift
//  TealiumSwift
//
//  Created by Christina S on 4/27/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol TimestampCollection {
    var currentTimeStamps: [String: Any] { get }
}

public protocol DataLayerManagerProtocol {
    var allEventData: [String: Any] { get set }
    var allSessionData: [String: Any] { get }
    var minutesBetweenSessionIdentifier: TimeInterval { get set }
    var secondsBetweenTrackEvents: TimeInterval { get set }
    var sessionId: String? { get set }
    var sessionData: [String: Any] { get set }
    var sessionStarter: SessionStarterProtocol { get }
    var isTagManagementEnabled: Bool { get set }
    func add(data: [String: Any], expiration: Expiration)
    func add(key: String, value: Any, expiration: Expiration)
    func joinTrace(id: String)
    func delete(for keys: [String])
    func delete(for key: String)
    func deleteAll()
    func leaveTrace()
    func refreshSessionData()
    func sessionRefresh()
    func startNewSession(with sessionStarter: SessionStarterProtocol)
}
