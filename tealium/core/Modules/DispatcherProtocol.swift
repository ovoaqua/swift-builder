//
//  DispatcherProtocol.swift
//  TealiumCore
//
//  Created by Craig Rouse on 23/04/2020.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public typealias DispatcherResult = Result<Void, Error>

public protocol Dispatcher: Module {
    var delegate: TealiumModuleDelegate { get }
    var isReady: Bool { get }
    init(config: TealiumConfig,
         delegate: TealiumModuleDelegate,
         eventDataManager: EventDataManagerProtocol?,
         completion: @escaping (DispatcherResult) -> Void)

    func dynamicTrack(_ request: TealiumRequest,
                      completion: ModuleCompletion?)
}
