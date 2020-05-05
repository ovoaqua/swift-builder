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
    var optionalCollectors: [String] = ["TealiumAttributionModule", "TealiumAttribution.TealiumAttributionModule", "TealiumLifecycle.LifecycleModule", "TealiumCrash.CrashModule", "TealiumAutotracking.TealiumAutotrackingModule"]
    var knownDispatchers: [String] = ["TealiumCollect.CollectModule", "TealiumTagManagement.TagManagementModule"]
    var collectors = [Collector]()
    var dispatchValidators = [DispatchValidator]()
    var dispatchManager: DispatchManager?
    var knownDispatchValidators: [DispatchValidator.Type] = []
    var dispatchers = [Dispatcher]()
    var eventDataManager: EventDataManagerProtocol?
    var logger: TealiumLoggerProtocol?
    public var modules = [Module]()
    var config: TealiumConfig? {
        willSet {
            guard let newValue = newValue else {
                return
            }
            self.dispatchManager?.config = newValue
            self.modules.forEach {
                var module = $0
                module.config = newValue
            }
        }
    }
    
    init (_ config: TealiumConfig,
          eventDataManager: EventDataManagerProtocol?) {
        TealiumQueues.backgroundConcurrentQueue.write {
            self.logger = config.logger
            self.eventDataManager = eventDataManager
            self.setupDispatchers(config: config)
            self.setupDispatchValidators(config: config)
            self.dispatchManager = DispatchManager(dispatchers: self.dispatchers, dispatchValidators: self.dispatchValidators, delegate: self, logger: self.logger, config: config)
            self.modules += self.collectors
            self.modules += self.dispatchers
            let logRequest = TealiumLogRequest(title: "Modules Manager Initialized", messages:
                ["Collectors Initialized: \(self.collectors.map { type(of: $0).moduleId })",
                "Dispatch Validators Initialized: \(self.dispatchValidators.map { $0.id })",
                "Dispatchers Initialized: \(self.dispatchers.map { type(of: $0).moduleId })"
            ], info: nil, logLevel: .info, category: .`init`)
            self.logger?.log(logRequest)
            
            self.setupCollectors(config: config)
        }
    }

    func setupCollectors(config: TealiumConfig) {
        knownCollectors.forEach { knownCollector in
            let collector = knownCollector.init(config: config, delegate: self, diskStorage: nil) {

            }
            guard collectors.contains(where: {
                type(of: $0) == knownCollector
            }) == false else {
                return
            }
            collectors.append(collector)
        }

        optionalCollectors.forEach { optionalCollector in
            guard let moduleRef = objc_getClass(optionalCollector) as? Collector.Type else {
                return
            }
            
            let collector = moduleRef.init(config: config, delegate: self, diskStorage: nil) {

            }
            guard self.collectors.contains(where: {
                type(of: $0) == moduleRef
            }) == false else {
                return
            }
            collectors.append(collector)
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
        knownDispatchers.forEach { knownDispatcher in
            guard let moduleRef = objc_getClass(knownDispatcher) as? Dispatcher.Type else {
                return
            }
            if knownDispatcher.contains("TagManagement") {
                self.eventDataManager?.tagManagementIsEnabled = true
            }
            
            let dispatcher = moduleRef.init(config: config, delegate: self, eventDataManager: eventDataManager) { result in
                switch result {
                case .failure(let error):
                    print("log error")
                default:
                    break
                }
            }

            guard self.dispatchers.contains(where: {
                type(of: $0) == moduleRef
            }) == false else {
                return
            }
            dispatchers.append(dispatcher)
        }
    }

    func track(_ request: TealiumTrackRequest) {
        let requestData = gatherTrackData(for: request.trackDictionary)
        let newRequest = TealiumTrackRequest(data: requestData, completion: request.completion)
        dispatchManager?.processTrack(newRequest)
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


extension NewModulesManager: TealiumModuleDelegate {
    public func tealiumModuleFinished(module: Module, process: TealiumRequest) {
        
    }
    
    public func tealiumModuleRequests(module: Module?, process: TealiumRequest) {
        switch process {
        case let request as TealiumTrackRequest:
//            sendTrack(request: request)
            track(request)
//            let logRequest = TealiumLogRequest(title: "Module Delegate", message: "Sending Batch Track Request", info: request.trackDictionary, logLevel: .info, category: .track)
//            self.logger?.log(logRequest)
        default:
            return
        }
    }
    
    
}
