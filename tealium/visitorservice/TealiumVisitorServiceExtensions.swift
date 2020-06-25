//
//  TealiumVisitorProfileExtensions.swift
//  tealium-swift
//
//  Created by Christina Sund on 5/16/19.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if visitorservice
import TealiumCore
#endif

extension Int64 {

    /// Converts minutes to milliseconds
    var milliseconds: Int64 {
        return self * 60 * 1000
    }
}

public extension Tealium {

    /// - Returns: `VisitorServiceManager` instance
    func visitorService() -> TealiumVisitorServiceManager? {
        (zz_internal_modulesManager?.modules.first {
            type(of: $0) == TealiumVisitorServiceModule.self
        } as? TealiumVisitorServiceModule)?.visitorServiceManager as? TealiumVisitorServiceManager
    }
}

public extension TealiumConfig {

    /// Sets the default refresh interval for visitor profile retrieval. Default is 5 minutes
    /// Set to `0` if the profile should always be fetched following a track request.
    var visitorServiceRefreshInterval: Int64? {
        get {
            options[TealiumVisitorServiceConstants.refreshInterval] as? Int64
        }

        set {
            options[TealiumVisitorServiceConstants.refreshInterval] = newValue
        }
    }

    /// Visitor service delegates to be notified of any changes to the visitor profile.
    /// Note: if no delegates are registered, no requests will be made to fetch the visitor profile from the server.
    var visitorServiceDelegate: TealiumVisitorServiceDelegate? {
        get {
            options[TealiumVisitorServiceConstants.visitorServiceDelegate] as? TealiumVisitorServiceDelegate
        }

        set {
            options[TealiumVisitorServiceConstants.visitorServiceDelegate] = newValue
        }
    }

    /// Overrides the default visitor service URL (visitor-service.tealiumiq.com).  If an invalid URL is passed, the default is used instead.
    /// Format: https://overridden-subdomain.yourdomain.com/
    var visitorServiceOverrideURL: String? {
        get {
            options[TealiumVisitorServiceConstants.visitorServiceOverrideURL] as? String
        }

        set {
            options[TealiumVisitorServiceConstants.visitorServiceOverrideURL] = newValue
        }
    }

    /// Sets a specific overridden profile from which to fetch the visitor profile.
    var visitorServiceOverrideProfile: String? {
        get {
            options[TealiumVisitorServiceConstants.visitorServiceOverrideProfile] as? String
        }

        set {
            options[TealiumVisitorServiceConstants.visitorServiceOverrideProfile] = newValue
        }
    }
}
