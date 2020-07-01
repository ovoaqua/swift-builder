//
//  CrashExtensions.swift
//  TealiumCrash
//
//  Created by Craig Rouse on 01/07/2020.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

#if crash
import TealiumCore
#endif

public extension Collectors {
    static let Crash = CrashModule.self
}
