//
//  DispatchManager.swift
//  TealiumCore
//
//  Created by Craig Rouse on 23/04/2020.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
#if os(iOS)
import UIKit
#else
#endif

class DispatchManager: DispatchValidator {

    var delegate: TealiumModuleDelegate
    var persistentQueue: TealiumPersistentDispatchQueue!
    var diskStorage: TealiumDiskStorageProtocol!
    var config: TealiumConfig
    var logger: TealiumLoggerProtocol?
    let id = "Dispatch Manager"
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
    
    required init (config: TealiumConfig,
          delegate: TealiumModuleDelegate) {
        self.config = config.copy
        self.logger = config.logger
        self.delegate = delegate
        // allows overriding for unit tests, independently of enable call
        if self.diskStorage == nil {
            self.diskStorage = diskStorage ?? TealiumDiskStorage(config: config, forModule: TealiumDispatchQueueConstants.moduleName)
        }
        persistentQueue = TealiumPersistentDispatchQueue(diskStorage: self.diskStorage)
        removeOldDispatches()
        Tealium.lifecycleListeners.addDelegate(delegate: self)
        registerForPowerNotifications()
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
        defer {
            if persistentQueue.currentEvents >= eventsBeforeAutoDispatch,
                hasSufficientBattery(track: persistentQueue.peek()?.last) {
                releaseQueue()
            }
        }
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
        if let queuedDispatches = persistentQueue.dequeueDispatches() {
            let batches: [[TealiumTrackRequest]] = queuedDispatches.chunks(maxDispatchSize)

            batches.forEach { batch in

                switch batch.count {
                case let val where val <= 1:
                    if var data = batch.first?.trackDictionary {
                        // for all release calls, bypass the queue and send immediately
                        data += [TealiumDispatchQueueConstants.bypassQueueKey: true]
                        let request = TealiumTrackRequest(data: data, completion: nil)
                            delegate.tealiumModuleRequests(module: nil,
                                                            process: request)
                    }

                case let val where val > 1:
                    let batchRequest = TealiumBatchTrackRequest(trackRequests: batch, completion: nil)
                        delegate.tealiumModuleRequests(module: nil,
                                                        process: batchRequest)
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
        delegate.tealiumModuleRequests(module: nil, process: request)
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
    
    func shouldDrop(request: TealiumRequest) -> Bool {
        return false
    }
    
    func shouldPurge(request: TealiumRequest) -> Bool {
        return false
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
