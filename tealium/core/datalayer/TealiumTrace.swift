//
//  TealiumTrace.swift
//  tealium-swift
//
//  Created by Craig Rouse on 12/04/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

public extension Tealium {

    /// Sends a request to modules to initiate a trace with a specific Trace ID￼.
    ///
    /// - Parameter id: String representing the Trace ID (usually 5-digit integer)
    func joinTrace(id: String) {
        dataLayer.joinTrace(id: id)
    }

    /// Sends a request to modules to leave a trace, and end the trace session￼.
    ///
    /// - Parameter killVisitorSession: Bool indicating whether the visitor session should be ended when the trace is left (default true).
    func leaveTrace(killVisitorSession: Bool = true) {
        if killVisitorSession {
            self.killVisitorSession()
        }
        dataLayer.leaveTrace()
    }

    /// Ends the current visitor session. Trace remains active, but visitor session is terminated.
    func killVisitorSession() {
        guard let traceId = self.zz_internal_modulesManager?.config.options[TealiumKey.traceId] as? String else {
            return
        }
        let dispatch = EventDispatch(TealiumKey.killVisitorSession, dataLayer: ["event": TealiumKey.killVisitorSession, "call_type": TealiumKey.killVisitorSession, TealiumKey.traceId: traceId])
        self.track(dispatch)
    }
}
