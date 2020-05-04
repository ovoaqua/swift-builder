//
//  TealiumLifecycleExtensions.swift
//  tealium-swift
//
//  Created by Craig Rouse on 28/08/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if lifecycle
import TealiumCore
#endif

// MARK: 
// MARK: EXTENSIONS

public extension Tealium {

    func lifecycle() -> TealiumLifecycleModule? {
        newModulesManager.modules.first {
            type(of: $0) == TealiumLifecycleModule.self
        } as? TealiumLifecycleModule
    }

}

public extension TealiumConfig {

    var lifecycleAutoTrackingEnabled: Bool {
        get {
            return optionalData[TealiumLifecycleConfigKey.autotrackingEnabled] as? Bool ?? true
        }

        set {
            optionalData[TealiumLifecycleConfigKey.autotrackingEnabled] = newValue
        }
    }

}

extension TealiumLifecycleModule: TealiumLifecycleEvents {
    public func sleep() {
        processDetected(type: .sleep)
    }

    public func wake() {
        processDetected(type: .wake)
    }

    public func launch(at date: Date) {
        processDetected(type: .launch, at: date)
    }
}
