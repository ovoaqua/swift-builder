//
//  TealiumLifecyclePersistentData.swift
//  tealium-swift
//
//  Created by Jason Koo on 11/17/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation
#if lifecycle
import TealiumCore
#endif

open class TealiumLifecyclePersistentData {

    let diskStorage: TealiumDiskStorageProtocol

    init(diskStorage: TealiumDiskStorageProtocol,
         uniqueId: String? = nil) {
        self.diskStorage = diskStorage
    }

    func load() -> TealiumLifecycle? {
        return diskStorage.retrieve(as: TealiumLifecycle.self)
    }

    func save(_ lifecycle: TealiumLifecycle) -> (success: Bool, error: Error?) {
        diskStorage.save(lifecycle, completion: nil)
        return (true, nil)
    }

}
