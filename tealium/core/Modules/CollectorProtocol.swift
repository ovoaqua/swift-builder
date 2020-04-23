//
//  CollectorProtocol.swift
//  TealiumCore
//
//  Created by Craig Rouse on 21/04/2020.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol Collector: Module {
    var data: [String: Any]? { get }
    init(config: TealiumConfig,
         diskStorage: TealiumDiskStorage?,
         completion: () -> Void)
}
