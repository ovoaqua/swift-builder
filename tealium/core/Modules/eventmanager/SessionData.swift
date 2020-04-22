//
//  SessionData.swift
//  TealiumSwift
//
//  Created by Christina S on 4/21/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol SessionDataCollection {
    var currentTimeStamps: [String: Any] { get }
}

public struct SessionData: SessionDataCollection {

    var eventDataManager: EventDataManager

    init(config: TealiumConfig) {
        eventDataManager = EventDataManager(config: config)
    }

    public var dictionary: [String: Any] {
        var data = [String: Any]()
        data[TealiumKey.random] = SessionData.getRandom(length: 16)
        if !dispatchHasExistingTimestamps(eventDataManager.allEventData) {
            data.merge(currentTimeStamps) { _, new -> Any in
                new
            }
            data[TealiumKey.timestampOffset] = timezoneOffset
            data[TealiumKey.timestampOffsetLegacy] = timezoneOffset
        }
        data += eventDataManager.sessionData
        return data
    }
    
    /// - Returns: `[String: Any]` containing all current timestamps in session data
    public var currentTimeStamps:  [String: Any] {
        let date = Date()
        return [
            TealiumKey.timestampEpoch: SessionData.getTimestampInSeconds(date),
            TealiumKey.timestamp: SessionData.getDate8601UTC(date),
            TealiumKey.timestampLocal: SessionData.getDate8601Local(date),
            TealiumKey.timestampUnixMilliseconds: date.unixTimeMilliseconds,
            TealiumKey.timestampUnix: date.unixTimeSeconds
        ]
    }
    
    /// - Returns: `String` containing the offset from UTC in hours
    var timezoneOffset: String {
        let timezone = TimeZone.current
        let offsetSeconds = timezone.secondsFromGMT()
        let offsetHours = offsetSeconds / 3600

        return String(format: "%i", offsetHours)
    }

    public func add(data: [String: Any]) {
        eventDataManager.add(data: data, expiration: .session)
    }

    public func add(value: Any, forKey: String) {
        eventDataManager.add(key: forKey,
            value: value,
            expiration: .session)
    }

    /// Checks that the dispatch contains all expected timestamps.
    ///
    /// - Parameter currentData: `[String: Any]` containing existing volatile data
    /// - Returns: `Bool` `true` if dispatch contains existing timestamps
    func dispatchHasExistingTimestamps(_ currentData: [String: Any]) -> Bool {
        return TealiumQueues.backgroundConcurrentQueue.read {
            return (currentData[TealiumKey.timestampEpoch] != nil) &&
                (currentData[TealiumKey.timestamp] != nil) &&
                (currentData[TealiumKey.timestampLocal] != nil) &&
                (currentData[TealiumKey.timestampOffset] != nil) &&
                (currentData[TealiumKey.timestampUnix] != nil)
        }
    }

    /// Deletes volatile data for specific keys.
    ///
    /// - Parameter keys: `[String]` to remove from the internal volatile data store.
    public func deleteData(forKeys keys: [String]) {
        keys.forEach {
            if eventDataManager.sessionData[$0] != nil {
                eventDataManager.sessionData[$0] = nil
            }
        }
    }

    public func delete(for key: String) {
        if eventDataManager.sessionData[key] != nil {
            eventDataManager.sessionData[key] = nil
        }
    }

    /// Deletes all volatile data.
    public func deleteAllData() {
        eventDataManager.deleteAll()
    }

    // ⚠️Currently in SessionManager branch
    /// Immediately resets the session ID.
//    public func resetSessionId() {
//        add(data: [TealiumKey.sessionId: TealiumVolatileData.newSessionId() ])
//    }

    // ⚠️Currently in SessionManager branch
    /// Manually set session id to a specified string.
    ///￼
    /// - Parameter sessionId: `String` id to set session id to.
//    public func setSessionId(sessionId: String) {
//        add(data: [TealiumKey.sessionId: sessionId])
//    }

    // MARK: INTERNAL

    /// Generates a random number of a specific length.
    ///
    /// - Parameter length: `Int` - the length of the random number
    /// - Returns: `String` containing a random integer of the specified length
    static func getRandom(length: Int) -> String {
        var randomNumber: String = ""

        for _ in 1...length {
            let random = Int(arc4random_uniform(10))
            randomNumber += String(random)
        }

        return randomNumber
    }

    /// - Parameter date: `Date`
    /// - Returns: `String` containing the timestamp in seconds from the `Date` object passed in
    public static func getTimestampInSeconds(_ date: Date) -> String {
        let timestamp = date.timeIntervalSince1970

        return "\(Int(timestamp))"
    }

    /// - Parameter date: `Date`
    /// - Returns: `String` containing the timestamp in milliseconds from the `Date` object passed in
    static func getTimestampInMilliseconds(_ date: Date) -> String {
        let timestamp = date.unixTimeMilliseconds

        return timestamp
    }

    // ⚠️Currently in SessionManager branch
    /// - Returns: `String` containing a new session ID
//    static func newSessionId() -> String {
//        return getTimestampInMilliseconds(Date())
//    }

    // ⚠️Currently in SessionManager branch
    /// - Returns: `Bool` `true` if the session ID should be updated (session has expired)
//    func shouldRefreshSessionIdentifier() -> Bool {
//        guard let lastTrackEvent = lastTrackEvent else {
//            return true
//        }
//
//        let timeDifference = lastTrackEvent.timeIntervalSinceNow
//        if abs(timeDifference) > minutesBetweenSessionIdentifier * 60 {
//            return true
//        }
//
//        return false
//    }

    /// - Parameter date: `Date`
    /// - Returns: `String` containing ISO8601 date in local timezone
    static func getDate8601Local(_ date: Date) -> String {
        return date.iso8601LocalString
    }

    /// - Parameter date: `Date`
    /// - Returns: `String` containing ISO8601 date in UTC time
    static func getDate8601UTC(_ date: Date) -> String {
        return date.iso8601String
    }

}

extension TealiumKey {
    static let timestampEpoch = "tealium_timestamp_epoch"
    static let timestampLegacy = "event_timestamp_iso"
    static let timestamp = "timestamp"
    static let timestampLocalLegacy = "event_timestamp_local_iso"
    static let timestampLocal = "timestamp_local"
    static let timestampOffsetLegacy = "event_timestamp_offset_hours"
    static let timestampOffset = "timestamp_offset"
    static let timestampUnixMillisecondsLegacy = "event_timestamp_unix_millis"
    static let timestampUnixLegacy = "event_timestamp_unix"
}
