//
//  TealiumModuleDelegate.swift
//  TealiumCore
//
//  Created by Craig Rouse on 23/04/2020.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol TealiumModuleDelegate: class {

    /// Called by module requesting an library operation.￼
    ///
    /// - Parameter module: Module making request.￼
    /// - Parameter process: TealiumModuleProcessType requested.
    func tealiumModuleRequests(module: Module?,
                               process: TealiumRequest)

}
