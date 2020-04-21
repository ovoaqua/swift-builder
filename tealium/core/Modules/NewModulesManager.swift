//
//  NewModulesManager.swift
//  TealiumCore
//
//  Created by Craig Rouse on 21/04/2020.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public class NewModulesManager {
    
    var knownCollectors: [Collector.Type] = [AppDataModule.self, DeviceDataModule.self]
    var collectors = [Collector]()
    
    init (_ config: TealiumConfig) {
        self.setupCollectors(config: config)
    }
    
    
    func setupCollectors(config: TealiumConfig) {
        TealiumQueues.backgroundConcurrentQueue.write { [weak self] in
            guard let self = self else {
                return
            }
            
            self.knownCollectors.forEach { knownCollector in
                let collector = knownCollector.init(config: config) {
                    
                }
                guard self.collectors.contains(where: {
                    type(of: $0) == knownCollector
                }) == false else {
                    return
                }
                self.collectors.append(collector)
            }
            
        }
    }
    
    func gatherTrackData(for data: [String: Any]?) -> [String: Any] {
        let allData = Atomic(value: [String: Any]())
        self.collectors.forEach {
            guard let data = $0.data else {
                return
            }
            allData.value += data
        }
        
        if let data = data {
            allData.value += data
        }
        return allData.value
    }
    
    
}
