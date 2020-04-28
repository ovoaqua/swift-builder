//
//  TealiumLogger.swift
//  tealium-swift
//
//  Created by Jonathan Wong on 1/10/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation
import os.log

@available (iOS 10.0, *)
extension OSLog {
    static let `init`: OSLog = OSLog(subsystem: "com.tealium.swift", category: "init")
    static let track: OSLog = OSLog(subsystem: "com.tealium.swift", category: "track")
    static let general: OSLog = OSLog(subsystem: "com.tealium.swift", category: "general")
}

/// Internal console logger for library debugging.
public struct TealiumLogger: TealiumLoggerProtocol {

    
    var logThreshold: TealiumLogLevel
    var loggerType: TealiumLoggerType
    
    /// Modules may initialize their own loggers, passing in the log level from the TealiumConfig object￼.
    ///
    /// - Parameters:
    ///     - logLevel: `TealiumLogLevel` indicating the type of errors that should be logged
    public init(config: TealiumConfig?) {
        self.logThreshold = config?.logLevel ?? TealiumConstants.defaultLogLevel
        self.loggerType = config?.loggerType ?? TealiumConstants.defaultLoggerType
    }

    /// Prints messages to the console￼.
    ///
    /// - Parameters:
    ///     - message: `String` containing the message to be logged￼
    ///     - logLevel: `TealiumLogLevel` indicating the severity of the message to be logged
    public func log(_ request: TealiumLogRequest) {
        switch loggerType {
        case .os:
            if #available(iOS 10.0, *) {
                osLog(request)
            } else {
                textLog(request)
            }
        case .print:
            textLog(request)
        default:
            textLog(request)
        }
    }
    
    @available(iOS 10.0, *)
    func osLog(_ request: LogRequest){
        
        guard logThreshold > .none else {
            return
        }
        
        let message = request.formattedString
        var logLevel: OSLogType
        switch request.logLevel {
        case .debug:
            logLevel = .debug
        case .info:
            logLevel = .info
        case .error:
            logLevel = .error
        case .fault:
            logLevel = .fault
        default:
            logLevel = .info
        }
        
        os_log("%{public}@", log: getLogCategory(request: request), type: logLevel, message)
    }
    
    @available(iOS 10.0, *)
    func getLogCategory(request: LogRequest) -> OSLog {
        switch request.logCategory {
        case .general:
            return .general
        case .track:
            return .track
        case .`init`:
            return .`init`
        default:
            return .general
        }
    }
    
    func textLog(_ request: TealiumLogRequest){
        guard logThreshold > .none,
            request.logLevel >= logThreshold else {
            return
        }
        print(request.formattedString)
    }

}
