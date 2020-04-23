//
//  TealiumVolatileData.swift
//  TealiumSwift
//
//  Created by Jonathan Wong on 1/10/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation

public class TealiumVolatileData {

    var eventDataManager: EventDataManagerProtocol

    public init(eventDataManager: EventDataManagerProtocol) {
        self.eventDataManager = eventDataManager
    }
    
    /// `[String: Any]` containing all active session data.
    public var dictionary: [String: Any] {
        eventDataManager.allSessionData
    }

    /// Add data to all dispatches for the remainder of an active session.
    ///
    /// - Parameter data: `[String: Any]`. Values should be of type `String` or `[String]`
    public func add(data: [String: Any]) {
        TealiumQueues.backgroundConcurrentQueue.write {
            self.eventDataManager.add(data: data, expiration: .session)
        }
    }
    
    /// Adds values to all dispatches for the remainder of an active session.
    /// - Parameters:
    ///   - value: Values should be of type `String` or `[String]`
    ///   - key: `String`
    public func add(value: Any, forKey key: String) {
        TealiumQueues.backgroundConcurrentQueue.write {
            self.eventDataManager.add(key: key, value: value, expiration: .session)
        }
    }

    /// Deletes session data for specific keys.
    ///
    /// - Parameter keys: `[String]` to remove from the internal session data store.
    public func deleteData(forKeys keys: [String]) {
        TealiumQueues.backgroundConcurrentQueue.write {
            keys.forEach {
                if self.eventDataManager.allSessionData[$0] != nil {
                    self.eventDataManager.allSessionData[$0] = nil
                }
            }
        }
    }

    /// Deletes session data for a specific key.
    /// - Parameter key: `String` to remove a specific value from the internal session data store.
    public func delete(for key: String) {
        TealiumQueues.backgroundConcurrentQueue.write {
            if self.eventDataManager.allSessionData[key] != nil {
                self.eventDataManager.allSessionData[key] = nil
            }
        }
    }

    /// Deletes all session data.
    public func deleteAllData() {
        TealiumQueues.backgroundConcurrentQueue.write {
            self.eventDataManager.allSessionData = [String: Any]()
        }
    }

}

