//
//  TealiumLoggerConstants.swift
//  tealium-swift
//
//  Created by Craig Rouse on 11/07/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

public extension TealiumConstants {
    static let defaultLogLevel = TealiumLogLevel.error
}

public enum TealiumLogLevel: Int, Comparable, CustomStringConvertible {
    
    case info = 0
    case debug = 100
    case error = 200
    case fault = 300
    case none = -9999
    
    public init(from string: String) {
        switch string {
        case "info":
            self = .info
        case "debug":
            self = .debug
        case "error":
            self = .error
        case "fault":
            self = .fault
        case "none":
            self = .none
        default:
            self = .none
        }
    }
    
    public var description: String {
        get {
            switch self {
            case .info:
                return "Info"
            case .debug:
                return "Debug"
            case .error:
                return "Error"
            case .fault:
                return "Fault"
            case .none:
                return "None"
            }
        }
    }
    
    public static func < (lhs: TealiumLogLevel, rhs: TealiumLogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public enum TealiumLoggerType {
    case print
    case os
    case custom(TealiumLoggerProtocol)
}

public extension TealiumConfig {
    var loggerType: TealiumLoggerType {
        get {
            optionalData[TealiumKey.loggerType] as? TealiumLoggerType ?? TealiumConstants.defaultLoggerType
        }
        
        set {
            optionalData[TealiumKey.loggerType] = newValue
        }
    }
    
    var logLevel: TealiumLogLevel? {
        get {
            optionalData[TealiumKey.logLevel] as? TealiumLogLevel
        }
        
        set {
            optionalData[TealiumKey.logLevel] = newValue
        }
    }
    
}
