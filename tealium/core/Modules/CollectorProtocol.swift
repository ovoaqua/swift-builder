//
//  CollectorProtocol.swift
//  TealiumCore
//
//  Created by Craig Rouse on 21/04/2020.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol Collector {
    var data: [String: Any]? { get }
    var collectorId: String { get }
    init(config: TealiumConfig,
         completion: ()-> Void)
}
