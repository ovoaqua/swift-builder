//
//  NewModulesManager.swift
//  TealiumCore
//
//  Created by Craig Rouse on 21/04/2020.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public class ModulesManager {

    var coreCollectors: [Collector.Type] = [TealiumAppDataModule.self, DeviceDataModule.self]
    var optionalCollectors: [String] = ["TealiumAttributionModule", "TealiumAttribution.TealiumAttributionModule", "TealiumLifecycle.LifecycleModule", "TealiumCrash.TealiumCrashModule", "TealiumAutotracking.TealiumAutotrackingModule", "TealiumVisitorService.TealiumVisitorServiceModule", "TealiumConsentManager.TealiumConsentManagerModule"]
    var knownDispatchers: [String] = ["TealiumCollect.TealiumCollectModule", "TealiumTagManagement.TealiumTagManagementModule"]
    public var collectors = [Collector]()
    var dispatchValidators = [DispatchValidator]()
    var dispatchManager: DispatchManager?
    
    var dispatchers = [Dispatcher]()
    var dispatchListeners = [DispatchListener]()
    var eventDataManager: EventDataManagerProtocol?
    var logger: TealiumLoggerProtocol?
    public var modules = [TealiumModule]()
    var config: TealiumConfig? {
        willSet {
            guard let newValue = newValue else {
                return
            }
            self.dispatchManager?.config = newValue
            self.updateConfig(config: newValue)
            self.modules.forEach {
                var module = $0
                module.config = newValue
            }
        }
    }
    
    init (_ config: TealiumConfig,
          eventDataManager: EventDataManagerProtocol?) {
            self.logger = config.logger
            self.eventDataManager = eventDataManager
            self.setupDispatchers(config: config)
            self.setupDispatchValidators(config: config)
            self.setupDispatchListeners(config: config)
            self.dispatchManager = DispatchManager(dispatchers: self.dispatchers, dispatchValidators: self.dispatchValidators, dispatchListeners: self.dispatchListeners, delegate: self, logger: self.logger, config: config)
            self.modules += self.collectors
            self.modules += self.dispatchers
            self.setupCollectors(config: config)
            let logRequest = TealiumLogRequest(title: "Modules Manager Initialized", messages:
                ["Collectors Initialized: \(self.collectors.map { $0.moduleId })",
                "Dispatch Validators Initialized: \(self.dispatchValidators.map { $0.id })",
                "Dispatchers Initialized: \(self.dispatchers.map { $0.moduleId })"
            ], info: nil, logLevel: .info, category: .`init`)
            self.logger?.log(logRequest)
    }
    
    func updateConfig(config: TealiumConfig) {
        if config.isCollectEnabled == false {
            disableModule(id: "Collect")
        }
        
        if config.isTagManagementEnabled == false {
            disableModule(id: "Tag Management")
        }
        
        self.setupDispatchers(config: config)
    }

    func addCollector(_ collector: Collector) {
        if let listener = collector as? DispatchListener {
            addDispatchListener(listener)
        }
        
        if let dispatchValidator = collector as? DispatchValidator {
            addDispatchValidator(dispatchValidator)
        }
        
        guard collectors.contains(where: {
            type(of: $0) == type(of: collector)
        }) == false else {
            return
        }
        collectors.append(collector)
    }
    
    // TODO: tidy this up. Need to update logic and remove duplication
    func addDispatchListener(_ listener: DispatchListener) {
        guard dispatchListeners.contains(where: {
            type(of: $0) == type(of: listener)
        }) == false else {
            return
        }
        dispatchListeners.append(listener)
        dispatchManager?.dispatchListeners.append(listener)
    }
    
    func addDispatchValidator(_ validator: DispatchValidator) {
        guard dispatchValidators.contains(where: {
            type(of: $0) == type(of: validator)
        }) == false else {
            return
        }
        dispatchValidators.append(validator)
        dispatchManager?.dispatchValidators.append(validator)
    }
    
    func addDispatcher(_ dispatcher: Dispatcher) {
        guard dispatchers.contains(where: {
            type(of: $0) == type(of: dispatcher)
        }) == false else {
            return
        }
        dispatchers.append(dispatcher)
    }
    
    func setupCollectors(config: TealiumConfig) {
        coreCollectors.forEach { coreCollector in
            let collector = coreCollector.init(config: config, delegate: self, diskStorage: nil) { result in

            }
            
            addCollector(collector)
        }

        optionalCollectors.forEach { optionalCollector in
            guard let moduleRef = objc_getClass(optionalCollector) as? Collector.Type else {
                return
            }
            
            let collector = moduleRef.init(config: config, delegate: self, diskStorage: nil) { result in

            }
            addCollector(collector)
        }
    }
    
    func setupDispatchers(config: TealiumConfig) {
        knownDispatchers.forEach { knownDispatcher in
            guard let moduleRef = objc_getClass(knownDispatcher) as? Dispatcher.Type else {
                return
            }
            
            if knownDispatcher.contains("TagManagement") {
                guard config.isTagManagementEnabled == true else {
                    return
                }
                self.eventDataManager?.tagManagementIsEnabled = true
            }
            
            if knownDispatcher.contains("Collect") {
                guard config.isCollectEnabled == true else {
                    return
                }
            }
            
            let dispatcher = moduleRef.init(config: config, delegate: self) { result in
                switch result {
                case .failure:
                    print("log error")
                default:
                    break
                }
            }

           addDispatcher(dispatcher)
        }
    }
    
//     TODO: allow dispatch validators to be set up from config, replaces delegate
    func setupDispatchValidators(config: TealiumConfig) {
        config.dispatchValidators?.forEach {
            self.addDispatchValidator($0)
        }
    }
    
    // TODO: allow dispatch listeners to be set up from config
    func setupDispatchListeners(config: TealiumConfig) {
        config.dispatchListeners?.forEach {
            self.addDispatchListener($0)
        }
    }

    func sendTrack(_ request: TealiumTrackRequest) {
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
        
        if let eventData = eventDataManager?.allEventData {
            allData.value += eventData
        }

        if let data = data {
            allData.value += data
        }
        return allData.value
    }
    
    func disableModule(id: String) {
        if let module = modules.first(where: { $0.moduleId == id }) {
            switch module {
            case let module as Dispatcher:
                self.collectors = self.collectors.filter { type(of: module) != type(of: $0) }
            case let module as Collector:
                self.dispatchers = self.dispatchers.filter { type(of: module) != type(of: $0) }
            default:
                return
            }
            self.modules = self.modules.filter { type(of: module) != type(of: $0) }
        }
    }
    
}


extension ModulesManager: TealiumModuleDelegate {
    public func requestTrack(_ track: TealiumTrackRequest) {
        TealiumQueues.backgroundConcurrentQueue.write {
            self.sendTrack(track)
        }
    }
}
