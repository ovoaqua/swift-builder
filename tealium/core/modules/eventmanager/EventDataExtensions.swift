//
//  EventDataExtensions.swift
//  TealiumSwift
//
//  Created by Christina S on 4/22/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public extension Tealium {

    /// Get the Data Manager instance for accessing file persistence and auto data variable APIs.
    ///
    /// - Returns: `TealiumPersistentData` instance
    func persistentData() -> TealiumPersistentData {
        return TealiumPersistentData(eventDataManager: eventDataManager)
    }
    
    /// Get the Data Manager instance for accessing file persistence and auto data variable APIs.
    ///
    /// - Returns: `TealiumVolatileData` instance 
    func volatileData() -> TealiumVolatileData {
        return TealiumVolatileData(eventDataManager: eventDataManager)
    }

}

public extension TealiumConfig {
    
    /// Enables session handling through native code versus through the webview and utag.js
    /// this prevents extra session counts from background events like push messages. This
    /// is currently disabled by default
    @available(*, deprecated, message: "Not currently released, for future use.")
    var sessionHandlingEnabled: Bool {
        get {
            return options[TealiumKey.sessionHandlingEnabled] as? Bool ?? false
        }

        set {
            options[TealiumKey.sessionHandlingEnabled] = newValue
        }
    }
    
}

public extension TealiumKey {
    static let timestampEpoch = "tealium_timestamp_epoch"
    static let timestamp = "timestamp"
    static let timestampLocal = "timestamp_local"
    static let timestampOffset = "timestamp_offset"
    static let defaultMinutesBetweenSession = 30
    static let defaultsSecondsBetweenTrackEvents = 30.0
    static let sessionBaseURL = "https://tags.tiqcdn.com/utag/tiqapp/utag.v.js?a="
    static let sessionHandlingEnabled = "session_handling_enabled"
}

extension Date {
    var timestampInSeconds: String {
        let timestamp = self.timeIntervalSince1970
        return "\(Int(timestamp))"
    }
    var timestampInMilliseconds: String {
        let timestamp = self.unixTimeMilliseconds
        return timestamp
    }
    
    func addSeconds(_ seconds: Double?) -> Date? {
        guard let seconds = seconds else {
            return nil
        }
        guard let timeInterval = TimeInterval(exactly: seconds) else {
            return nil
        }
        return addingTimeInterval(timeInterval)
    }
}

public extension String {
    var dateFromISOString: Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return dateFormatter.date(from: self)
    }
}

public enum SessionError: Error {
    case errorInRequest
    case invalidResponse
    case invalidURL
}

extension SessionError: LocalizedError {
    public var description: String {
        switch self {
        case .errorInRequest:
            return NSLocalizedString("Error when requesting a new session: ", comment: "errorInRequest")
        case .invalidResponse:
            return NSLocalizedString("Invalid response when requesting a new session.", comment: "invalidResponse")
        case .invalidURL:
            return NSLocalizedString("The url is invalid.", comment: "invalidURL")
        }
    }
}
