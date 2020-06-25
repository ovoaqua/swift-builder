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
    var collectOverrideProfile: String? {
        get {
            options[TealiumCollectKey.overrideCollectProfile] as? String
        }

        set {
            options[TealiumCollectKey.overrideCollectProfile] = newValue
        }
    }
}
