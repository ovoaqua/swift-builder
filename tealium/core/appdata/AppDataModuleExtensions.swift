//
//  AppDataModuleExtensions.swift
//  TealiumCore
//
//  Created by Craig Rouse on 06/07/2020.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public extension Collectors {
    static let AppData = AppDataModule.self
}

//// public interface for AppData module
//public extension Tealium {
//
//    /// - Returns: `AppData` module instance
//    internal var appData: AppDataModule? {
//        let module = zz_internal_modulesManager?.collectors.first {
//            $0 is AppDataModule
//        }
//        return (module as? AppDataModule)
//    }
//
//}
