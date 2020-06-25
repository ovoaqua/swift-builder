//
//  TealiumCollectExtensions.swift
//  tealium-swift
//
//  Created by Craig Rouse on 19/03/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if collect
import TealiumCore
#endif

public extension TealiumConfig {

    /// Overrides the default Collect endpoint URL￼.
    ///
    /// - Parameter string: `String` representing the URL to which all Collect module dispatches should be sent
    @available(*, deprecated, message: "Please switch to config.collectOverrideURL")
    func setCollectOverrideURL(url: String) {
        collectOverrideURL = url
    }

    var collectOverrideURL: String? {
        get {
            options[TealiumCollectKey.overrideCollectUrl] as? String
        }

        set {
            guard let newValue = newValue else {
                return
            }
            if newValue.contains("vdata") {
                var urlString = newValue
                var lastChar: Character?
                lastChar = urlString.last

                if lastChar != "&" {
                    urlString += "&"
                }
                options[TealiumCollectKey.overrideCollectUrl] = urlString
            } else {
                options[TealiumCollectKey.overrideCollectUrl] = newValue
            }
        }
    }

    /// Overrides the default Collect endpoint profile￼.
    ///
    /// - Parameter profile: `String` containing the name of the Tealium profile to which all Collect module dispatches should be sent
    @available(*, deprecated, message: "Please switch to config.collectOverrideProfile")
    func setCollectOverrideProfile(profile: String) {
        collectOverrideProfile = profile
    }

    var collectOverrideProfile: String? {
        get {
            options[TealiumCollectKey.overrideCollectProfile] as? String
        }

        set {
            options[TealiumCollectKey.overrideCollectProfile] = newValue
        }
    }
}
