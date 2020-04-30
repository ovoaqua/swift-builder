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
    var optionalCollectors: [String] = ["TealiumAttributionModule", "TealiumAttribution.TealiumAttributionModule", "TealiumLifecycle.LifecycleModule"]
    var knownDispatchers: [String] = ["TealiumCollect.CollectModule", "TealiumTagManagement.TagManagementModule"]
    var collectors = [Collector]()
    var dispatchValidators = [DispatchValidator]()
    var dispatchManager: DispatchManager?
    var knownDispatchValidators = [DispatchManager.self]
    var dispatchers = [Dispatcher]()
    var eventDataManager: EventDataManagerProtocol?
    var logger: TealiumLoggerProtocol?
    
    init (_ config: TealiumConfig,
          eventDataManager: EventDataManagerProtocol?) {
        TealiumQueues.backgroundConcurrentQueue.write {
            self.logger = config.logger
            self.eventDataManager = eventDataManager
            self.setupCollectors(config: config)
            self.setupDispatchers(config: config)
            self.setupDispatchValidators(config: config)
            self.dispatchManager = self.dispatchValidators.filter { $0 as? DispatchManager != nil }.first as? DispatchManager
            let logRequest = TealiumLogRequest(title: "Modules Manager Initialized", messages:
                ["Collectors Initialized: \(self.collectors.map { type(of: $0).moduleId })",
                "Dispatch Validators Initialized: \(self.dispatchValidators.map { $0.id })",
                "Dispatchers Initialized: \(self.dispatchers.map { type(of: $0).moduleId })"
            ], info: nil, logLevel: .info, category: .`init`)
            self.logger?.log(logRequest)
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
        // TODO: Have dispatchers return Result type and log after all dispatchers finished.
        var errorResponses = [(module: String, error: Error)]()
        var successResponses = [String]()
        let dispatchersResponded = Atomic(value: 0)
        dispatchers.forEach { module in
            let moduleId = type(of: module).moduleId
            module.dynamicTrack(request) { result in
                dispatchersResponded.value += 1
                switch result {
                case .failure(let error):
                    errorResponses.append((module: moduleId, error: error))
                case .success:
                    successResponses.append(moduleId)
                }
                if dispatchersResponded.value == self.dispatchers.count {
                    if successResponses.count > 0 {
                        self.logTrackSuccess(successResponses, request: request)
                    }
                    if errorResponses.count > 0 {
                        self.logTrackFailure(errorResponses, request: request)
                    }
                }
            }
        }
//        logTrackSuccess(successResponses, request: request)
        
    }
    
    func logTrackSuccess(_ success: [String],
                         request: TealiumRequest) {
        var logInfo: [String: Any]? = [String: Any]()
        switch request {
        case let request as TealiumTrackRequest:
            logInfo = request.trackDictionary
        case let request as TealiumBatchTrackRequest:
            logInfo = request.compressed()
        default:
            return
        }
        let logRequest = TealiumLogRequest(title: "Successful Track", messages: success.map { "\($0) Successful Track"}, info: logInfo, logLevel: .info, category: .track)
        logger?.log(logRequest)
    }

    func logTrackFailure(_ failures: [(module: String, error: Error)],
                         request: TealiumRequest) {
        var logInfo: [String: Any]? = [String: Any]()
        switch request {
        case let request as TealiumTrackRequest:
            logInfo = request.trackDictionary
        case let request as TealiumBatchTrackRequest:
            logInfo = request.compressed()
        default:
            return
        }
        let logRequest = TealiumLogRequest(title: "Failed Track", messages: failures.map { "\($0.module) Error -> \($0.error.localizedDescription)"}, info: logInfo, logLevel: .error, category: .track)
        logger?.log(logRequest)
    }
    
}


extension NewModulesManager: TealiumModuleDelegate {
    public func tealiumModuleFinished(module: TealiumModule, process: TealiumRequest) {
        
    }
    
    public func tealiumModuleRequests(module: TealiumModule?, process: TealiumRequest) {
        switch process {
        case let request as TealiumBatchTrackRequest:
            sendBatch(request: request)
//            let logRequest = TealiumLogRequest(title: "Module Delegate", message: "Sending Batch Track Request", info: request.compressed(), logLevel: .info, category: .track)
//            self.logger?.log(logRequest)
        case let request as TealiumTrackRequest:
            sendTrack(request: request)
//            let logRequest = TealiumLogRequest(title: "Module Delegate", message: "Sending Batch Track Request", info: request.trackDictionary, logLevel: .info, category: .track)
//            self.logger?.log(logRequest)
        default:
            return
        }
    }
    
    
}
