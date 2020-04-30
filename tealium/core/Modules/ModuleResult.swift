//
//  ModuleResult.swift
//  TealiumCore
//
//  Created by Craig Rouse on 29/04/2020.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public typealias ModuleResult = Result<Void, Error>

public typealias ModuleCompletion = ((ModuleResult) -> Void)
