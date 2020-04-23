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
    var allSessionData: [String: Any] { get set }
    var lastTrackEvent: Date? { get set }
    var sessionId: String? { get set }
    var sessionExpired: Bool { get }
    func add(data: [String: Any], expiration: Expiration)
    func add(key: String, value: Any, expiration: Expiration)
    func delete(forKeys: [String])
    func delete(forKey key: String)
    func deleteAll()
    func expireSessionData()
}

public class EventDataManager: EventDataManagerProtocol {

    // need to check for existing session data in storage first
    var sessionData = [String: Any]()
    var restartData = [String: Any]()
    var data = Set<EventDataItem>()
    public var minutesBetweenSessionIdentifier: TimeInterval = 30.0
    public var lastTrackEvent: Date?
    var diskStorage: TealiumDiskStorageProtocol
    // var isLoaded: Atomic<Bool> = Atomic(value: false)

    /// - Returns: `EventData` containing all stored event data
    private var persistentDataStorage: EventData? {
        get {
            return self.diskStorage.retrieve(as: EventData.self)
        }

        set {
            if let newData = newValue?.removeExpired() {
                self.diskStorage.save(newData, completion: nil)
            }
        }
    }
    
    /// - Returns: `[String: Any]` containing all stored event data
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
    
    /// - Returns: `[String: Any]` containing all data for the active session
    public var allSessionData: [String: Any] {
        get {
            var allSessionData = [String: Any]()
            allSessionData[TealiumKey.random] = "\(Int.random(in: 1...16))"
            if !dispatchHasExistingTimestamps(allSessionData) {
                allSessionData.merge(currentTimeStamps) { _, new -> Any in
                    new
                }
                allSessionData[TealiumKey.timestampOffset] = timezoneOffset
            }
            allSessionData += sessionData
            return allSessionData
        }
        set {
            self.add(data: newValue, expiration: .session)
        }
    }

    /// - Returns: `[String: Any]` containing all current timestamps in volatile data
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

    /// - Returns: `String` containing a new session ID
    public static var newSessionId: String {
        Date().timestampInMilliseconds
    }
    
    /// - Returns: `String` session id for the active session
    public var sessionId: String? {
        get {
            return allSessionData[TealiumKey.sessionId] as? String
        }
        set {
            allSessionData[TealiumKey.sessionId] = newValue
            add(data: [TealiumKey.sessionId: newValue as Any],
                expiration: .session)
        }
    }

    /// - Returns: `Bool` `true` if the session ID should be updated
    /// and all other session data should be removed
    public var sessionExpired: Bool {
        guard let lastTrackEvent = lastTrackEvent else {
            return true
        }

        let timeDifference = lastTrackEvent.timeIntervalSinceNow
        if abs(timeDifference) > minutesBetweenSessionIdentifier * 60 {
            return true
        }

        return false
    }

    /// - Returns: `String` containing the offset from UTC in hours
    var timezoneOffset: String {
        let timezone = TimeZone.current
        let offsetSeconds = timezone.secondsFromGMT()
        let offsetHours = offsetSeconds / 3600
        return String(format: "%i", offsetHours)
    }

    public init(config: TealiumConfig,
        diskStorage: TealiumDiskStorageProtocol? = nil) {
        self.diskStorage = TealiumDiskStorage(config: config, forModule: "eventdata")
        var currentStaticData = [TealiumKey.account: config.account,
            TealiumKey.profile: config.profile,
            TealiumKey.environment: config.environment,
            TealiumKey.libraryName: TealiumValue.libraryName,
            TealiumKey.libraryVersion: TealiumValue.libraryVersion]
        if let dataSource = config.datasource {
            currentStaticData[TealiumKey.dataSource] = dataSource
        }
        add(data: currentStaticData, expiration: .untilRestart)
    }

    /// Adds data to be stored based on the `Expiraton`
    /// - Parameters:
    ///   - key: `String` name of key to be stored
    ///   - value: `Any` should be `String` or `[String]`
    ///   - expiration: `Expiration` level
    public func add(key: String,
        value: Any,
        expiration: Expiration) {
        self.add(data: [key: value], expiration: expiration)
    }

    /// Adds data to be stored based on the `Expiraton`
    /// - Parameters:
    ///   - data: `[String: Any]` to be stored
    ///   - expiration: `Expiration` level
    public func add(data: [String: Any],
        expiration: Expiration) {
        switch expiration {
        case .session:
//            print("⏰adding session data")
            self.sessionData += data
//            sessionData.forEach {
//                print("key=\($0.key), value=\($0.value)")
//            }
        case .untilRestart:
            //print("♻️adding restart data")
            self.restartData += data
//            restartExpiration.forEach {
//                print("key=\($0.key), value=\($0.value)")
//            }
        default:
//            print("🙃adding default w exp date: \(expiration.date)")
//            data.forEach {
//                print("key=\($0.key), value=\($0.value)")
//            }
            self.persistentDataStorage?.insertNew(from: data, expires: expiration.date)
        }
    }

    /// Removes session data and resets sessionId
    public func expireSessionData() {
        allSessionData = [String: Any]()
        allSessionData[TealiumKey.sessionId] = EventDataManager.newSessionId
    }

    /// Checks that the dispatch contains all expected timestamps.
    ///
    /// - Parameter currentData: `[String: Any]` containing existing volatile data
    /// - Returns: `Bool` `true` if dispatch contains existing timestamps
    func dispatchHasExistingTimestamps(_ currentData: [String: Any]) -> Bool {
        TealiumQueues.backgroundConcurrentQueue.read {
            currentData[TealiumKey.timestampEpoch] != nil &&
                currentData[TealiumKey.timestamp] != nil &&
                currentData[TealiumKey.timestampLocal] != nil &&
                currentData[TealiumKey.timestampOffset] != nil &&
                currentData[TealiumKey.timestampUnix] != nil
        }
    }

    /// Adds traceId to the payload for debugging server side integrations
    /// - Parameter id: `String` traceId from server side interface
    public func addTrace(id: String) {
        add(key: TealiumKey.traceId, value: id, expiration: .session)
    }

    /// Ends the trace current session
    public func leaveTrace() {
        delete(forKey: TealiumKey.traceId)
    }
    
    /// Deletes specified values from storage
    /// - Parameter forKeys: `[String]` keys to delete
    public func delete(forKeys: [String]) {
        forKeys.forEach {
            self.delete(forKey: $0)
        }
    }
    
    /// Deletes a value from storage
    /// - Parameter key: `String` to delete
    public func delete(forKey key: String) {
        persistentDataStorage?.remove(key: key)
    }
    
    /// Deletes all values from storage
    public func deleteAll() {
        persistentDataStorage?.removeAll()
    }

}


