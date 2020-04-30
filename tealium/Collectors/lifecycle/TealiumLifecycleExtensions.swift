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

//public extension Tealium {
//
//    func lifecycle() -> TealiumLifecycleModule? {
//        guard let module = modulesManager.getModule(forName: TealiumLifecycleModuleKey.moduleName) as? TealiumLifecycleModule else {
//            return nil
//        }
//
//        return module
//    }
//
//}

public extension TealiumConfig {

    var lifecycleAutoTrackingEnabled: Bool {
        get {
            return optionalData[LifecycleKey.autotrackingEnabled] as? Bool ?? true
        }

        set {
            optionalData[LifecycleKey.autotrackingEnabled] = newValue
        }
    }

}

//extension TealiumLifecycleModule: TealiumLifecycleEvents {
//    public func sleep() {
//        processDetected(type: .sleep)
//    }
//
//    public func wake() {
//        processDetected(type: .wake)
//    }
//
//    public func launch(at date: Date) {
//        processDetected(type: .launch, at: date)
//    }
//}

//public func ==(lhs: TealiumLifecycle, rhs: TealiumLifecycle ) -> Bool {
//    if lhs.countCrashTotal != rhs.countCrashTotal { return false }
//    if lhs.countLaunchTotal != rhs.countLaunchTotal { return false }
//    if lhs.countSleepTotal != rhs.countSleepTotal { return false }
//    if lhs.countWakeTotal != rhs.countWakeTotal { return false }
//
//    return true
//}

extension Bundle {
    var version: String? {
            return object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ??
                object(forInfoDictionaryKey: "CFBundleVersion") as? String
    }
}


extension Array where Element == TealiumLifecycleSession {

    /// Get item before last
    ///
    /// - Returns: Target item or item at index 0 if only 1 item.
    var beforeLast: Element? {
        if self.isEmpty {
            return nil
        }

        var index = self.count - 2
        if index < 0 {
            index = 0
        }
        return self[index]
    }

}
