//
//  DispatchManager.swift
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

class DispatchManager {
    
    var dispatchers = [Dispatcher]()
    var dispatchValidators = [DispatchValidator]()
    var dispatchListeners = [DispatchListener]()
    var logger: TealiumLoggerProtocol?
    var persistentQueue: TealiumPersistentDispatchQueue!
    var diskStorage: TealiumDiskStorageProtocol!
    var config: TealiumConfig
    var connectivityManager: TealiumConnectivity
    var isConnected: Bool {
        self.connectivityManager.hasViableConnection
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
         dispatchListeners: [DispatchListener]?,
         delegate: TealiumModuleDelegate?,
         connectivityManager: TealiumConnectivity,
         logger: TealiumLoggerProtocol?,
         config: TealiumConfig) {
        self.config = config
        self.connectivityManager = connectivityManager
        if let dispatchers = dispatchers {
            self.dispatchers = dispatchers
        }
        
        if let dispatchValidators = dispatchValidators {
            self.dispatchValidators = dispatchValidators
        }
        
        if let listeners = dispatchListeners {
            self.dispatchListeners = listeners
        }
        
        if let logger = logger {
            self.logger = logger
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
            let batchingReason = shouldQueue.1? ["queue_reason"] as? String ?? "batching_enabled"
            
            self.enqueue(request, reason: batchingReason)
            // batch request and release if necessary
            return
        }
        
        if self.dispatchers.isEmpty {
            self.enqueue(request, reason: "Dispatchers Not Ready")
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
                let logRequest = TealiumLogRequest(title: "Dispatch Manager", message: "Track request enqueued by Dispatch Validator: \($0.id)", info: data, logLevel: .info, category: .track)
                self.logger?.log(logRequest)
            }
            return response.0
        }.count > 0
    }
    
    func checkShouldQueue(request: inout TealiumBatchTrackRequest) -> Bool {
        let uuid = request.uuid
        return dispatchValidators.filter {
            let response = $0.shouldQueue(request: request)
            if response.0 == true,
                let data = response.1 {
                request = TealiumBatchTrackRequest(trackRequests: request.trackRequests.map { request in
                    let singleRequestUUID = request.uuid
                    var newData = request.trackDictionary
                    newData += data
                    var newRequest = TealiumTrackRequest(data: newData, completion: request.completion)
                    newRequest.uuid = singleRequestUUID
                    return newRequest
                }, completion: request.completion)
                request.uuid = uuid
                let logRequest = TealiumLogRequest(title: "Dispatch Manager", message: "Track request enqueued by Dispatch Validator: \($0.id)", info: data, logLevel: .info, category: .track)
                self.logger?.log(logRequest)
            }
            return response.0
        }.count > 0
    }
    
    var allDispatchersReady: Bool {
        return dispatchers.filter { !$0.isReady }.count == 0
    }
    
    func checkShouldDrop(request: TealiumRequest) -> Bool {
        dispatchValidators.filter {
            if $0.shouldDrop(request: request) == true {
                let logRequest = TealiumLogRequest(title: "Dispatch Manager", message: "Track request dropped by Dispatch Validator: \($0.id)", info: nil, logLevel: .info, category: .track)
                self.logger?.log(logRequest)
                return true
            }
            return false
        }.count > 0
    }
    
    func checkShouldPurge(request: TealiumRequest) -> Bool {
        dispatchValidators.filter {
            if $0.shouldPurge(request: request) == true {
                let logRequest = TealiumLogRequest(title: "Dispatch Manager", message: "Purge request received from Dispatch Validator: \($0.id)", info: nil, logLevel: .info, category: .track)
                self.logger?.log(logRequest)
                return true
            }
            return false
        }.count > 0
    }
    
    func runDispatchers (for request: TealiumRequest) {
        if request is TealiumTrackRequest || request is TealiumBatchTrackRequest {
            self.dispatchListeners.forEach {
                $0.willTrack(request: request)
            }
        }
        self.logTrackSuccess([], request: request)
        dispatchers.forEach { module in
            let moduleId = module.moduleId
            module.dynamicTrack(request) { result in
                switch result.0 {
                case .failure(let error):
                    self.logModuleResponse(for: moduleId, request: request, info: result.1, success: false, error: error)
                case .success:
                    self.logModuleResponse(for: moduleId, request: request, info: result.1, success: true, error: nil)
                }
                
            }
        }
    }
    
    func logModuleResponse (for module: String,
                            request: TealiumRequest,
                            info: [String: Any]?,
                            success: Bool,
                            error: Error?) {
        let message = success ? "Successful Track": "Failed with error: \(error?.localizedDescription ?? "")"
        let logLevel: TealiumLogLevel = success ? .info : .error
        var uuid: String?
        var event: String?
        switch request {
        case let request as TealiumBatchTrackRequest:
            uuid = request.uuid
            event = "batch"
        case let request as TealiumTrackRequest:
            uuid = request.uuid
            event = request.event()
        default:
            uuid = nil
        }
        var messages = [String]()
        if let uuid = uuid, let event = event {
            messages.append("Event: \(event), Track UUID: \(uuid)")
        }
        messages.append(message)
        let logRequest = TealiumLogRequest(title: module, messages: messages, info: nil, logLevel: logLevel, category: .track)
        logger?.log(logRequest)
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

        let logRequest = TealiumLogRequest(title: "Dispatch Manager", message: "Sending dispatch", info: logInfo, logLevel: .info, category: .track)
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
            let uuid = $0.uuid
            var newTrack = TealiumTrackRequest(data: newData,
                                               completion: $0.completion)
            newTrack.uuid = uuid
            persistentQueue.appendDispatch(newTrack)
            logQueue(request: newTrack, reason: nil)
        }
    }
    
    func enqueue(_ request: TealiumTrackRequest,
                 reason: String?) {
        defer {
            if !self.dispatchers.isEmpty {
                if persistentQueue.currentEvents >= eventsBeforeAutoDispatch,
                    hasSufficientBattery(track: persistentQueue.peek()?.last) {
                    handleReleaseRequest(reason: "Dispatch queue limit reached.")
                }
            }
        }
        // no conditions preventing queueing, so queue request
        var requestData = request.trackDictionary
        requestData[TealiumKey.queueReason] = reason ?? TealiumKey.batchingEnabled
        requestData[TealiumKey.wasQueued] = "true"
        var newRequest = TealiumTrackRequest(data: requestData, completion: request.completion)
        newRequest.uuid = request.uuid
        persistentQueue.appendDispatch(newRequest)

        logQueue(request: newRequest, reason: reason)
    }
    
    
    func clearQueue() {
        persistentQueue.clearQueue()
    }
    
    func handleReleaseRequest(reason: String) {
        guard isConnected else {
            return
        }
        
        // dummy request to check if queueing active
        var request = TealiumTrackRequest(data: ["release_request":true])
        
        guard !self.dispatchers.isEmpty else {
            return
        }
        
        guard !checkShouldQueue(request: &request),
            !checkShouldDrop(request: request),
            !checkShouldPurge(request: request) else {
                return
        }
        
        if let count = persistentQueue.peek()?.count, count > 0 {
            let logRequest = TealiumLogRequest(title: "Dispatch Manager", message: "Releasing queued dispatches. Reason: \(reason)", info: nil, logLevel: .info, category: .track)
                self.logger?.log(logRequest)
            
                self.releaseQueue()
        }
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
                        runDispatchers(for: request)
                    }

                case let val where val > 1:
                    let batchRequest = TealiumBatchTrackRequest(trackRequests: batch, completion: nil)
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
        runDispatchers(for: request)
    }
    
    func logQueue(request: TealiumTrackRequest,
                  reason: String?) {
        
        let message = """
        Event: \(request.trackDictionary[TealiumKey.event] as? String ?? "") queued for batch dispatch. Track UUID: \(request.uuid)
        """
        var messages = [message]
        if let reason = reason {
            messages.append("Queue Reason: \(reason)")
        }
        let logRequest = TealiumLogRequest(title: "Dispatch Manager", messages: messages, info: nil, logLevel: .info, category: .track)
        
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
        
    }
    
    func connectionRestored() {
        handleReleaseRequest(reason: "Connectivity Restored")
        
    }
}
