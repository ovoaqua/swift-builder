//
//  DeviceDataExtensions.swift
//  tealium-swift
//
//  Created by Craig Rouse on 20/08/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

public extension TealiumConfig {

    var memoryReportingEnabled: Bool {
        get {
            return options[DeviceDataModuleKey.isMemoryReportingEnabled] as? Bool ?? false
        }

        set {
            options[DeviceDataModuleKey.isMemoryReportingEnabled] = newValue
        }
    }

}
