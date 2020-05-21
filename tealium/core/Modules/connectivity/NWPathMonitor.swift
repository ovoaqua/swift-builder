//
//  NWPathMonitor.swift
//  TealiumCore
//
//  Created by Craig Rouse on 20/05/2020.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
#if canImport(Network)
import Network
#endif

@available(iOS 12, *)
@available(tvOS 12, *)
@available(watchOS 5, *)
@available(macCatalyst 13, *)
@available(OSX 10.14, *)
class TealiumNWPathMonitor: TealiumConnectivityMonitorProtocol {
    
    var currentConnnectionType: String? {
        guard isConnected == true else {
            return TealiumConnectivityKey.connectionTypeNone
        }
        if isCellular == true {
            return TealiumConnectivityKey.connectionTypeCell
        }
        if isWifi == true {
            return TealiumConnectivityKey.connectionTypeWifi
        }
        
        if isWired == true {
            return TealiumConnectivityKey.connectionTypeWired
        }
        return TealiumConnectivityKey.connectionTypeUnknown
    }
    
    var monitor = NWPathMonitor()
    let queue = TealiumQueues.backgroundSerialQueue
    
    var isConnected: Bool? {
        let connected = (monitor.currentPath.status == .satisfied)
        if config.wifiOnlySending == true, isExpensive == true {
            return false
        } else {
            return connected
        }
    }
    
    var isExpensive: Bool? {
        monitor.currentPath.isExpensive
    }
    
    var isCellular: Bool? {
        monitor.currentPath.usesInterfaceType(.cellular)
    }
    
    var isWifi: Bool? {
        monitor.currentPath.usesInterfaceType(.wifi)
    }
    
    var isWired: Bool? {
        monitor.currentPath.usesInterfaceType(.wiredEthernet)
    }
    
    var completion:  ((Result<Bool, Error>) -> Void)
    
    var config: TealiumConfig
    
    required init(config: TealiumConfig,
                  completion: @escaping ((Result<Bool, Error>) -> Void)) {
        self.config = config
        self.completion = completion
        
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else {
                return
            }
            switch path.status {
            case .satisfied:
                if config.wifiOnlySending == true, path.isExpensive {
                        self.completion(.failure(TealiumConnectivityError.noConnection))
                } else {
                    self.completion(.success(true))
                }
            default:
                self.completion(.failure(TealiumConnectivityError.noConnection))
            }
        }
        monitor.start(queue: queue)
    }
    
    func checkIsConnected(completion: @escaping ((Result<Bool, Error>) -> Void)) {
        switch isConnected {
        case true:
            completion(.success(true))
        default:
            completion(.failure(TealiumConnectivityError.noConnection))
        }
    }
    
}

enum TealiumConnectivityError: Error {
    case noConnection
}
