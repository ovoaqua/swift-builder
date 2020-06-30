//
//  Trace.swift
//  TealiumSwift
//
//  Created by Christina S on 4/27/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public extension DataLayerManager {

    /// Adds traceId to the payload for debugging server side integrations.
    /// - Parameter id: `String` traceId from server side interface.
    func joinTrace(id: String) {
        add(key: TealiumKey.traceId, value: id, expiration: .session)
    }

    /// Ends the trace for the current session.
    func leaveTrace() {
        delete(forKey: TealiumKey.traceId)
    }
}
