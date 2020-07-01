//
//  TealiumConnectivityConfigExtensions.swift
//  tealium-swift
//
//  Created by Craig Rouse on 20/03/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

public extension TealiumConfig {

    /// Sets the interval with which new connectivity checks will be carried out.
    var connectivityRefreshInterval: Int? {
        get {
            options[TealiumConnectivityKey.refreshIntervalKey] as? Int
        }

        set {
            options[TealiumConnectivityKey.refreshIntervalKey] = newValue
        }
    }

    /// Determines if connectivity status checks should be carried out automatically.
    /// If `true` (default), queued track calls will be flushed when connectivity is restored.
    var connectivityRefreshEnabled: Bool? {
        get {
            options[TealiumConnectivityKey.refreshEnabledKey] as? Bool
        }

        set {
            options[TealiumConnectivityKey.refreshEnabledKey] = newValue
        }
    }
}

public extension Collectors {
    static let Connectivity = ConnectivityModule.self
}
