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
    var knownDispatchers: [String] = ["TealiumCollect.CollectModule"
//        , "TealiumTagManagement.TealiumTagManagementModule"
    ]
    var collectors = [Collector]()
    var dispatchValidators = [DispatchValidator]()
    var dispatchManager: DispatchManager?
    var knownDispatchValidators = [DispatchManager.self]
    var dispatchers = [Dispatcher]()

    init (_ config: TealiumConfig) {
        self.setupCollectors(config: config)
        self.setupDispatchers(config: config)
        self.setupDispatchValidators(config: config)
        self.dispatchManager = dispatchValidators.filter { $0 as? DispatchManager != nil }.first as? DispatchManager
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
    
    func setupDispatchValidators(config: TealiumConfig) {
        knownDispatchValidators.forEach { dispatchValidator in
            let validator = dispatchValidator.init(config: config, delegate: self)
            guard self.dispatchValidators.contains(where: {
                type(of: $0) == dispatchValidator
            }) == false else {
                return
            }
            self.dispatchValidators.append(validator)
        }
    }
    
    func setupDispatchers(config: TealiumConfig) {
        self.knownDispatchers.forEach { knownDispatcher in
            guard let moduleRef = objc_getClass(knownDispatcher) as? Dispatcher.Type else {
                return
            }

            let dispatcher = moduleRef.init(config: config, delegate: self)
            guard self.dispatchers.contains(where: {
                type(of: $0) == moduleRef
            }) == false else {
                return
            }
            self.dispatchers.append(dispatcher)
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
    
    func sendTrack(request: TealiumTrackRequest) {
        let requestData = gatherTrackData(for: request.trackDictionary)
        var newRequest = TealiumCore.TealiumTrackRequest(data: requestData, completion: request.completion)
        
        if checkShouldQueue(request: &newRequest) {
            let enqueueRequest = TealiumEnqueueRequest(data: request, completion: nil)
            dispatchManager?.queue(enqueueRequest)
            return
        }
        
        if checkShouldDrop(request: newRequest) {
            return
        }
        
        if checkShouldPurge(request: newRequest) {
            dispatchManager?.clearQueue()
            return
        }
        
        runDispatchers(for: newRequest)
    }
    
    func sendBatch(request: TealiumBatchTrackRequest) {
        if checkShouldPurge(request: request) {
            return
        }
        
        if checkShouldDrop(request: request) {
            return
        }
        
        runDispatchers(for: request)
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
    
    func checkShouldDrop(request: TealiumRequest) -> Bool {
        dispatchValidators.filter {
            $0.shouldDrop(request: request)
        }.count > 0
    }
    
    func checkShouldPurge(request: TealiumRequest) -> Bool {
        dispatchValidators.filter {
            $0.shouldPurge(request: request)
        }.count > 0
    }
    
    func runDispatchers (for request: TealiumRequest) {
        dispatchers.forEach {
            $0.dynamicTrack(request)
        }
    }

}


extension NewModulesManager: TealiumModuleDelegate {
    public func tealiumModuleFinished(module: TealiumModule, process: TealiumRequest) {
        
    }
    
    public func tealiumModuleRequests(module: TealiumModule?, process: TealiumRequest) {
        switch process {
        case let request as TealiumBatchTrackRequest:
            sendBatch(request: request)
        case let request as TealiumTrackRequest:
            sendTrack(request: request)
        default:
            return
        }
    }
    
    
}
