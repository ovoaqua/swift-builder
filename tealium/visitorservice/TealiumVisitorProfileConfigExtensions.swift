//
//  TealiumVisitorProfileConfigExtensions.swift
//  tealium-swift
//
//  Created by Christina Sund on 5/16/19.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if visitorservice
import TealiumCore
#endif

public extension TealiumConfig {

    func setVisitorProfileRefresh(interval: Int) {
        optionalData[TealiumVisitorProfileConstants.refreshInterval] = interval
    }

    func addVisitorProfileDelegate(_ delegate: TealiumVisitorProfileDelegate) {
        var delegates = getVisitorProfileDelegates() ?? [TealiumVisitorProfileDelegate]()
        delegates.append(delegate)
        optionalData[TealiumVisitorProfileConstants.visitorProfileDelegate] = delegates
    }

    func getVisitorProfileDelegates() -> [TealiumVisitorProfileDelegate]? {
        return optionalData[TealiumVisitorProfileConstants.visitorProfileDelegate] as? [TealiumVisitorProfileDelegate]
    }
}
