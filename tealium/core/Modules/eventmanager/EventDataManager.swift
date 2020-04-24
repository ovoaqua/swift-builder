//
//  EventDataManager.swift
//  TealiumSwift
//
//  Created by Craig Rouse on 4/21/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol EventDataManagerProtocol {
    var allEventData: [String: Any] { get set }
    var allSessionData: [String: Any] { get }
    var lastSessionIdRefresh: Date? { get set }
    var lastSessionRequest: Date? { get set }
    var qualifiedByMultipleTracks: Bool { get set }
    var secondsBetweenTrackEvents: TimeInterval { get set }
    var sessionId: String? { get set }
    var sessionData: [String: Any] { get set }
    var sessionExpired: Bool { get }
    func add(data: [String: Any], expiration: Expiration)
    func add(key: String, value: Any, expiration: Expiration)
    func delete(forKeys: [String])
    func delete(forKey key: String)
    func deleteAll()
    func refreshSessionData()
    func generateSessionId()
}

public class EventDataManager: EventDataManagerProtocol {

    // TODO: need to figure out how to split restart and session data from forever data
    // when user queries for it
    
    var data = Set<EventDataItem>()
    var diskStorage: TealiumDiskStorageProtocol
    var restartData = [String: Any]()
    public var lastSessionIdRefresh: Date?
    public var lastSessionRequest: Date?
    public var minutesBetweenSessionIdentifier: TimeInterval
    public var qualifiedByMultipleTracks: Bool = false
    public var secondsBetweenTrackEvents: TimeInterval = TealiumKey.defaultsSecondsBetweenTrackEvents
    public var sessionData = [String: Any]()
    
    /// - Returns: `EventData` containing all stored event data.
    private var persistentDataStorage: EventData? {
        get {
            guard let storedData = self.diskStorage.retrieve(as: EventData.self) else {
                return EventData()
            }
            return storedData
        }
        set {
            if let newData = newValue?.removeExpired() {
                self.diskStorage.save(newData, completion: nil)
            }
        }
    }
    
    /// - Returns: `[String: Any]` containing all stored event data.
    public var allEventData: [String: Any] {
        get {
            var allData = [String: Any]()
            if let persistentData = self.persistentDataStorage {
                allData += persistentData.allData
            }
            allData += self.restartData
            allData += self.allSessionData
            return allData
        }
        set {
            self.add(data: newValue, expiration: .forever)
        }
    }
    
    /// - Returns: `[String: Any]` containing all data for the active session.
    public var allSessionData: [String: Any] {
        get {
            var allSessionData = [String: Any]()
            if let persistentData = self.persistentDataStorage {
                allSessionData += persistentData.allData
            }
            
            allSessionData[TealiumKey.random] = "\(Int.random(in: 1...16))"
            if !currentTimestampsExist(allSessionData) {
                allSessionData.merge(currentTimeStamps) { _ , new in new }
                allSessionData[TealiumKey.timestampOffset] = timezoneOffset
            }
            allSessionData += sessionData
            return allSessionData
        }
    }

    /// - Returns: `[String: Any]` containing all current timestamps in volatile data.
    public var currentTimeStamps: [String: Any] {
        let date = Date()
        return [
            TealiumKey.timestampEpoch: date.timestampInSeconds,
            TealiumKey.timestamp: date.iso8601String,
            TealiumKey.timestampLocal: date.iso8601LocalString,
            TealiumKey.timestampUnixMilliseconds: date.unixTimeMilliseconds,
            TealiumKey.timestampUnix: date.unixTimeSeconds
        ]
    }
    
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
        guard let lastTrackEvent = lastSessionIdRefresh else {
            return true
        }

        let timeDifference = lastTrackEvent.timeIntervalSinceNow
        if abs(timeDifference) > minutesBetweenSessionIdentifier * 60 {
            return true
        }

        return false
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
        guard let sessionId = allEventData[TealiumKey.lastSessionId] as? String else {
            return nil
        }
        return sessionId
    }

    /// - Returns: `String` containing the offset from UTC in hours.
    var timezoneOffset: String {
        let timezone = TimeZone.current
        let offsetSeconds = timezone.secondsFromGMT()
        let offsetHours = offsetSeconds / 3600
        return String(format: "%i", offsetHours)
    }

    public init(config: TealiumConfig,
        diskStorage: TealiumDiskStorageProtocol? = nil) {
        self.diskStorage = TealiumDiskStorage(config: config, forModule: "eventdata")
        self.minutesBetweenSessionIdentifier = TimeInterval(TealiumKey.defaultMinutesBetweenSession)
        var currentStaticData = [TealiumKey.account: config.account,
            TealiumKey.profile: config.profile,
            TealiumKey.environment: config.environment,
            TealiumKey.libraryName: TealiumValue.libraryName,
            TealiumKey.libraryVersion: TealiumValue.libraryVersion]
       
        if let dataSource = config.datasource {
            currentStaticData[TealiumKey.dataSource] = dataSource
        }
        
        add(data: currentStaticData, expiration: .untilRestart)
        
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

        refreshSessionData()
        lastSessionIdRefresh = Date()
        add(data: [TealiumKey.sessionId: sessionId ?? "",
                   TealiumKey.lastSessionIdRefresh: lastSessionIdRefresh!.extendedIso8601String],
            expiration: .session)
    }

    /// Adds data to be stored based on the `Expiraton`.
    /// - Parameters:
    ///   - key: `String` name of key to be stored.
    ///   - value: `Any` should be `String` or `[String]`.
    ///   - expiration: `Expiration` level.
    public func add(key: String,
        value: Any,
        expiration: Expiration) {
        self.add(data: [key: value], expiration: expiration)
    }

    /// Adds data to be stored based on the `Expiraton`.
    /// - Parameters:
    ///   - data: `[String: Any]` to be stored.
    ///   - expiration: `Expiration` level.
    public func add(data: [String: Any],
        expiration: Expiration) {
        switch expiration {
        case .session:
            print("⏰adding session data")
            self.sessionData += data
            sessionData.forEach {
                print("⏰key=\($0.key), value=\($0.value)")
            }
        case .untilRestart:
            // print("♻️adding restart data")
            self.restartData += data
//            restartData.forEach {
//                print("♻️key=\($0.key), value=\($0.value)")
//            }
        default:
            break
        }
        self.persistentDataStorage?.insertNew(from: data, expires: expiration.date)
    }

    /// Removes session data and resets session
    public func refreshSessionData() {
        sessionData = [String: Any]()
        generateSessionId()
    }
    
    /// Checks that the active session data contains all expected timestamps.
    ///
    /// - Parameter currentData: `[String: Any]` containing existing session data.
    /// - Returns: `Bool` `true` if current timestamps exist in active session data.
    func currentTimestampsExist(_ currentData: [String: Any]) -> Bool {
        TealiumQueues.backgroundConcurrentQueue.read {
            currentData[TealiumKey.timestampEpoch] != nil &&
                currentData[TealiumKey.timestamp] != nil &&
                currentData[TealiumKey.timestampLocal] != nil &&
                currentData[TealiumKey.timestampOffset] != nil &&
                currentData[TealiumKey.timestampUnix] != nil
        }
    }
    
    /// Generates a new sessionId.
    public func generateSessionId() {
        sessionId = Date().unixTimeMilliseconds
    }

    /// Adds traceId to the payload for debugging server side integrations.
    /// - Parameter id: `String` traceId from server side interface.
    public func addTrace(id: String) {
        add(key: TealiumKey.traceId, value: id, expiration: .session)
    }

    /// Ends the trace current session.
    public func leaveTrace() {
        delete(forKey: TealiumKey.traceId)
    }
    
    /// Deletes specified values from storage.
    /// - Parameter forKeys: `[String]` keys to delete.
    public func delete(forKeys: [String]) {
        forKeys.forEach {
            self.delete(forKey: $0)
        }
    }
    
    /// Deletes a value from storage.
    /// - Parameter key: `String` to delete.
    public func delete(forKey key: String) {
        persistentDataStorage?.remove(key: key)
    }
    
    /// Deletes all values from storage.
    public func deleteAll() {
        persistentDataStorage?.removeAll()
    }

}


