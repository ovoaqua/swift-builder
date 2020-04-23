//
//  DispatcherProtocol.swift
//  TealiumCore
//
//  Created by Craig Rouse on 23/04/2020.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol Dispatcher: Module {
    var delegate: TealiumDelegate? { get }
    init(config: TealiumConfig,
         delegate: TealiumModuleDelegate?)
    func track(request: TealiumRequest)
}
