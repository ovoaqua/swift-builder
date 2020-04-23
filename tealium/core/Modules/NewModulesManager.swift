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
    var optionalCollectors: [String] = ["TealiumAttributionModule", "TealiumAttribution.TealiumAttributionModule"]
    var knownDispatchers: [String] = ["TealiumCollect.TealiumCollectModule", "TealiumTagManagement.TealiumTagManagementModule"]
    var collectors = [Collector]()
    var dispatchValidators = [DispatchValidator]()
    var dispatchers = [Dispatcher]()

    init (_ config: TealiumConfig) {
        self.setupCollectors(config: config)
    }

    func setupCollectors(config: TealiumConfig) {
        TealiumQueues.backgroundConcurrentQueue.write { [weak self] in
            guard let self = self else {
                return
            }

            self.knownCollectors.forEach { knownCollector in
                let collector = knownCollector.init(config: config, diskStorage: nil) {

                }
                guard self.collectors.contains(where: {
                    type(of: $0) == knownCollector
                }) == false else {
                    return
                }
                self.collectors.append(collector)
            }

            self.optionalCollectors.forEach { optionalCollector in
                guard let moduleRef = objc_getClass(optionalCollector) as? Collector.Type else {
                    return
                }

                let collector = moduleRef.init(config: config, diskStorage: nil) {

                }
                guard self.collectors.contains(where: {
                    type(of: $0) == moduleRef
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
    
    func sendTrack(request: TealiumCore.TealiumTrackRequest) {
        let requestData = gatherTrackData(for: request.trackDictionary)
        var newRequest = TealiumCore.TealiumTrackRequest(data: requestData, completion: request.completion)
        
        if checkShouldQueue(request: &newRequest) {
            return
        }
        
        if checkShouldDrop(request: newRequest) {
            return
        }
        
        if checkShouldPurge(request: newRequest) {
            return
        }
        
        runDispatchers(for: newRequest)
    }
    
    func checkShouldQueue(request: inout TealiumTrackRequest) -> Bool {
        dispatchValidators.filter {
            let response = $0.shouldQueue(request: request)
            if response.0 == true, let data = response.1?.encodable {
                request.data = data
            }
            return response.0
        }.count > 0
    }
    
    func checkShouldDrop(request: TealiumTrackRequest) -> Bool {
        dispatchValidators.filter {
            $0.shouldDrop(request: request)
        }.count > 0
    }
    
    func checkShouldPurge(request: TealiumTrackRequest) -> Bool {
        dispatchValidators.filter {
            $0.shouldPurge(request: request)
        }.count > 0
    }
    
    func runDispatchers (for request: TealiumRequest) {
        dispatchers.forEach {
            $0.track(request: request)
        }
    }

}


extension NewModulesManager: TealiumModuleDelegate {
    public func tealiumModuleFinished(module: TealiumModule, process: TealiumRequest) {
        
    }
    
    public func tealiumModuleRequests(module: TealiumModule?, process: TealiumRequest) {
        // todo - will batch track ever be requested?
        guard let request = process as? TealiumTrackRequest else {
            return
        }
        sendTrack(request: request)
    }
    
    
}
