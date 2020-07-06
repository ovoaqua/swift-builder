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

// public interface for consent manager
public extension Tealium {

    /// - Returns: `ConsentManager` instance
    internal var appData: AppDataModule? {
        let module = zz_internal_modulesManager?.collectors.first {
            $0 is AppDataModule
        }
        return (module as? AppDataModule)
    }

    var visitorId: String? {
        self.appData?.appData.persistentData?.visitorId
    }

}
