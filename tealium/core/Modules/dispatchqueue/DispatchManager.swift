//
//  NewDispatchManager.swift
//  TealiumCore
//
//  Created by Craig Rouse on 30/04/2020.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
#if os(iOS)
import UIKit
#else
#endif

class DispatchManager: TealiumConnectivityDelegate {
    
    var dispatchers = [Dispatcher]()
    var dispatchValidators = [DispatchValidator]()
    var logger: TealiumLoggerProtocol?
    var delegate: TealiumModuleDelegate?
    var persistentQueue: TealiumPersistentDispatchQueue!
    var diskStorage: TealiumDiskStorageProtocol!
    var config: TealiumConfig
    var connectivityManager: TealiumConnectivity
    var isConnected: Bool {
        let connected = TealiumConnectivity.isConnectedToNetwork() == true || (config.wifiOnlySending == true && TealiumConnectivity.currentConnectionType() == TealiumConnectivityKey.connectionTypeWifi)
        if connected == false {
            connectivityManager.refreshConnectivityStatus()
        }
        return connected
    }

    // when to start trimming the queue (default 20) - e.g. if offline
    var maxQueueSize: Int {
        if let maxQueueSize = config.dispatchQueueLimit, maxQueueSize >= 0 {
            return maxQueueSize
        }
        return TealiumValue.defaultMaxQueueSize
    }

    // max number of events in a single batch
    var maxDispatchSize: Int {
        config.batchSize
    }

    var eventsBeforeAutoDispatch: Int {
        config.dispatchAfter
    }

    var isBatchingEnabled: Bool {
        config.batchingEnabled ?? true
    }

    var batchingBypassKeys: [String]? {
        get {
            config.batchingBypassKeys
        }

        set {
            config.batchingBypassKeys = newValue
        }
    }

    var batchExpirationDays: Int {
        config.dispatchExpiration ?? TealiumValue.defaultBatchExpirationDays
    }

    var isRemoteAPIEnabled: Bool {
            #if os(iOS)
            return config.remoteAPIEnabled ?? false
            #else
            return false
            #endif
    }

    var lowPowerModeEnabled = false
    var lowPowerNotificationObserver: NSObjectProtocol?

    #if os(iOS)
    class var sharedApplication: UIApplication? {
        let selector = NSSelectorFromString("sharedApplication")
        return UIApplication.perform(selector)?.takeUnretainedValue() as? UIApplication
    }
    #endif
    
    init(dispatchers: [Dispatcher]?,
         dispatchValidators: [DispatchValidator]?,
         delegate: TealiumModuleDelegate?,
         logger: TealiumLoggerProtocol?,
         config: TealiumConfig) {
        self.config = config
        self.connectivityManager = TealiumConnectivity(config: config)
        self.connectivityManager.connectivityDelegates.add(self)
        if let dispatchers = dispatchers {
            self.dispatchers = dispatchers
        }
        
        if let dispatchValidators = dispatchValidators {
            self.dispatchValidators = dispatchValidators
        }
        
        if let logger = logger {
            self.logger = logger
        }
        
        if let delegate = delegate {
            self.delegate = delegate
        }
        // allows overriding for unit tests, independently of enable call
        if self.diskStorage == nil {
            self.diskStorage = diskStorage ?? TealiumDiskStorage(config: config, forModule: TealiumDispatchQueueConstants.moduleName)
        }
        persistentQueue = TealiumPersistentDispatchQueue(diskStorage: self.diskStorage)
        removeOldDispatches()
        if config.lifecycleAutoTrackingEnabled {
           Tealium.lifecycleListeners.addDelegate(delegate: self)
        }
        registerForPowerNotifications()
    }
    
    
    func processTrack(_ request: TealiumTrackRequest) {
        var newRequest = request
        triggerRemoteAPIRequest(request)
        if checkShouldQueue(request: &newRequest) {
            let enqueueRequest = TealiumEnqueueRequest(data: newRequest, completion: nil)
//            dispatchManager?.queue(enqueueRequest)
            queue(enqueueRequest)
            return
        }
        
        if checkShouldDrop(request: newRequest) {
            return
        }
        
        if checkShouldPurge(request: newRequest) {
            self.clearQueue()
            return
        }
        
        let shouldQueue = self.shouldQueue(request: newRequest)
        if shouldQueue.0 == true {
//            dispatchManager?.clearQueue()
            let batchingReason = shouldQueue.1? ["queue_reason"] as? String ?? "batching_enabled"
            
            self.enqueue(request, reason: batchingReason)
            // batch request and release if necessary
            return
        }
        
        runDispatchers(for: newRequest)
    }
    
    func checkShouldQueue(request: inout TealiumTrackRequest) -> Bool {
        dispatchValidators.filter {
            let response = $0.shouldQueue(request: request)
            if response.0 == true, let data = response.1 {
                var newData = request.trackDictionary
                newData += data
                request.data = newData.encodable
            }
            return response.0
        }.count > 0
    }
    
    func checkShouldQueue(request: inout TealiumBatchTrackRequest) -> Bool {
        dispatchValidators.filter {
            let response = $0.shouldQueue(request: request)
            if response.0 == true,
                let data = response.1 {
                request = TealiumBatchTrackRequest(trackRequests: request.trackRequests.map { request in
                    var newData = request.trackDictionary
                    newData += data
                    return TealiumTrackRequest(data: newData, completion: request.completion)
                }, completion: request.completion)
            }
            return response.0
        }.count > 0
    }
    
    var allDispatchersReady: Bool {
        return dispatchers.filter { !$0.isReady }.count == 0
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
    
    func removeOldDispatches() {
        let currentDate = Date()
        var components = DateComponents()
        components.calendar = Calendar.autoupdatingCurrent
        components.setValue(-batchExpirationDays, for: .day)
        let sinceDate = Calendar(identifier: .gregorian).date(byAdding: components, to: currentDate)
        persistentQueue.removeOldDispatches(maxQueueSize, since: sinceDate)
    }
    
    func queue(_ request: TealiumEnqueueRequest) {
        removeOldDispatches()
        let allTrackRequests = request.data

        allTrackRequests.forEach {
            var newData = $0.trackDictionary
            newData[TealiumKey.wasQueued] = "true"
            let newTrack = TealiumTrackRequest(data: newData,
                                               completion: $0.completion)
            persistentQueue.appendDispatch(newTrack)
            logQueue(request: newTrack)
        }
    }
    
    func enqueue(_ request: TealiumTrackRequest,
                 reason: String?) {
        defer {
            if persistentQueue.currentEvents >= eventsBeforeAutoDispatch,
                hasSufficientBattery(track: persistentQueue.peek()?.last) {
                releaseQueue()
            }
        }
        // no conditions preventing queueing, so queue request
        var requestData = request.trackDictionary
        requestData[TealiumKey.queueReason] = reason ?? TealiumKey.batchingEnabled
        requestData[TealiumKey.wasQueued] = "true"
        let newRequest = TealiumTrackRequest(data: requestData, completion: request.completion)
        persistentQueue.appendDispatch(newRequest)

        logQueue(request: newRequest)
    }
    
    
    func clearQueue() {
        persistentQueue.clearQueue()
    }
    
    func releaseQueue() {
        guard isConnected else {
            return
        }
        if let queuedDispatches = persistentQueue.dequeueDispatches() {
            let batches: [[TealiumTrackRequest]] = queuedDispatches.chunks(maxDispatchSize)

            batches.forEach { batch in

                switch batch.count {
                case let val where val <= 1:
                    if var data = batch.first?.trackDictionary {
                        // for all release calls, bypass the queue and send immediately
                        data += [TealiumDispatchQueueConstants.bypassQueueKey: true]
                        let request = TealiumTrackRequest(data: data, completion: nil)
//                            delegate.tealiumModuleRequests(module: nil,
//                                                            process: request)
                        runDispatchers(for: request)
                    }

                case let val where val > 1:
                    let batchRequest = TealiumBatchTrackRequest(trackRequests: batch, completion: nil)
//                        delegate.tealiumModuleRequests(module: nil,
//                                                        process: batchRequest)
                    runDispatchers(for: batchRequest)
                default:
                    // should never reach here
                    return
                }

            }
        }
    }
    
    func triggerRemoteAPIRequest(_ request: TealiumTrackRequest) {
        guard isRemoteAPIEnabled else {
            return
        }
        let request = TealiumRemoteAPIRequest(trackRequest: request)
//        delegate.tealiumModuleRequests(module: nil, process: request)
        runDispatchers(for: request)
    }
    
    func logQueue(request: TealiumTrackRequest) {
        let message = """
        ⏳ Event: \(request.trackDictionary[TealiumKey.event] as? String ?? "") queued for batch dispatch
        """
        
        let logRequest = TealiumLogRequest(title: "Dispatch Manager", message: message, info: nil, logLevel: .info, category: .track)
        
        logger?.log(logRequest)
    }
    
}

extension DispatchManager {
    
    func shouldQueue(request: TealiumRequest) -> (Bool, [String : Any]?) {
        
        guard let request = request as? TealiumTrackRequest else {
            return (false, nil)
        }
        
        let canWrite = diskStorage.canWrite()

        guard canWrite else {
            return (false, nil)
        }
        
        guard isConnected else {
            return (true, ["queue_reason": "connectivity"])
        }
        
        guard hasSufficientBattery(track: request) else {
            enqueue(request, reason: TealiumDispatchQueueConstants.insufficientBatteryQueueReason)
            return (true, ["queue_reason": TealiumDispatchQueueConstants.insufficientBatteryQueueReason])
        }
        
        if request.trackDictionary[TealiumDispatchQueueConstants.bypassQueueKey] as? Bool == true {
            return (!(request.trackDictionary[TealiumDispatchQueueConstants.bypassQueueKey] as? Bool ?? false), nil)
        }
        
        guard isBatchingEnabled else {
            return (false, nil)
        }

        guard eventsBeforeAutoDispatch > 1 else {
            return (false, nil)
        }

        guard maxDispatchSize > 1 else {
            return (false, nil)
        }

        guard maxQueueSize > 1 else {
            return (false, nil)
        }

        guard canQueueRequest(request) else {
            return (false, nil)
        }

        return (true, ["queue_reason": "batching_enabled"])
    }
    
    
    func hasSufficientBattery(track: TealiumTrackRequest?) -> Bool {
        guard let track = track else {
            return true
        }
        guard config.batterySaverEnabled == true else {
            return true
        }

        if lowPowerModeEnabled == true {
            return false
        }

        guard let batteryPercentString = track.trackDictionary["battery_percent"] as? String, let batteryPercent = Double(batteryPercentString) else {
            return true
        }

        // simulator case
        guard batteryPercent != TealiumDispatchQueueConstants.simulatorBatteryConstant else {
            return true
        }

        guard batteryPercent >= TealiumDispatchQueueConstants.lowBatteryThreshold else {
            return false
        }
        return true
    }
    
    func canQueueRequest(_ request: TealiumTrackRequest) -> Bool {
        guard let event = request.event() else {
            return false
        }
        var shouldQueue = true
        var bypassKeys = BypassDispatchQueueKeys.allCases.map { $0.rawValue }
        if let batchingBypassKeys = batchingBypassKeys {
            bypassKeys += batchingBypassKeys
        }
        for key in bypassKeys where key == event {
                shouldQueue = false
                break
        }

        return shouldQueue
    }
    
    
}

extension DispatchManager {
    func connectionTypeChanged(_ connectionType: String) {
        logger?.log(TealiumLogRequest(title: "Dispatch Manager", message: "Connectivity type changed to \(connectionType)", info: nil, logLevel: .info, category: .general))
    }
    
    func connectionLost() {
        logger?.log(TealiumLogRequest(title: "Dispatch Manager", message: "Connectivity lost", info: nil, logLevel: .info, category: .general))
    }
    
    func connectionRestored() {
        releaseQueue()
        connectivityManager.cancelAutoStatusRefresh()
    }
}
