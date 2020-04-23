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
        return TealiumPersistentData(eventDataManager: self.eventDataManager)
    }
    
    /// Get the Data Manager instance for accessing file persistence and auto data variable APIs.
    ///
    /// - Returns: `TealiumVolatileData` instance 
    func volatileData() -> TealiumVolatileData {
        return TealiumVolatileData(eventDataManager: self.eventDataManager)
    }

}

extension TealiumKey {
    static let timestampEpoch = "tealium_timestamp_epoch"
    static let timestamp = "timestamp"
    static let timestampLocal = "timestamp_local"
    static let timestampOffset = "timestamp_offset"
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
}
