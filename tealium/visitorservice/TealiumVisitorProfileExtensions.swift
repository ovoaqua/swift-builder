//
//  TealiumVisitorProfileExtensions.swift
//  tealium-swift
//
//  Created by Christina Sund on 6/11/19.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if visitorservice
import TealiumCore
#endif

extension Int {

    /// Converts minutes to milliseconds
    var milliseconds: Int {
        return self * 60 * 1000
    }
}

public extension Tealium {

    /// - Returns: `VisitorProfileManager` instance
    func visitorService() -> TealiumVisitorProfileManager? {
        guard let module = modulesManager.getModule(forName: TealiumVisitorProfileConstants.moduleName) as? TealiumVisitorServiceModule else {
            return nil
        }

        return module.visitorProfileManager as? TealiumVisitorProfileManager
    }
}
