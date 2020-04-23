//
//  DispatchValidatorProtocol.swift
//  TealiumCore
//
//  Created by Craig Rouse on 23/04/2020.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol DispatchValidator {
    func shouldQueue(request: TealiumRequest)
    func shouldDrop(request: TealiumRequest)
}
