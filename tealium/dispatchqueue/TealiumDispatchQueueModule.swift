//
//  TealiumDispatchQueueModule.swift
//  tealium-swift
//
//  Created by Craig Rouse on 4/9/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation
#if dispatchqueue
import TealiumCore
#endif
#if os(iOS)
import UIKit
#else
#endif

class TealiumDispatchQueueModule: TealiumModule {

    var persistentQueue: TealiumPersistentDispatchQueue!
    var diskStorage: TealiumDiskStorageProtocol!

    // when to start trimming the queue (default 20) - e.g. if offline
//    var maxQueueSize = TealiumDispatchQueueConstants.defaultMaxQueueSize

    var maxQueueSize: Int {
        config?.dispatchQueueLimit ?? TealiumDispatchQueueConstants.defaultMaxQueueSize
    }

    // max number of events in a single batch
    var maxDispatchSize: Int {
        config?.batchSize ?? TealiumValue.maxEventBatchSize
    }

    var eventsBeforeAutoDispatch: Int {
        config?.dispatchAfter ?? maxDispatchSize
    }

    var isBatchingEnabled: Bool {
        config?.batchingEnabled ?? true
    }

    var batchingBypassKeys: [String]? {
        config?.batchingBypassKeys
    }

    var batchExpirationDays: Int {
        config?.dispatchExpiration ?? TealiumDispatchQueueConstants.defaultBatchExpirationDays
    }

    var isRemoteAPIEnabled: Bool {
            #if os(iOS)
            return config?.remoteAPIEnabled ?? false
            #else
            return false
            #endif
    }

    #if os(iOS)
    class var sharedApplication: UIApplication? {
        let selector = NSSelectorFromString("sharedApplication")
        return UIApplication.perform(selector)?.takeUnretainedValue() as? UIApplication
    }
    #endif

    override class func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumDispatchQueueConstants.moduleName,
                                   priority: 1000,
                                   build: 1,
                                   enabled: true)
    }

    override func enable(_ request: TealiumEnableRequest) {
        enable(request, diskStorage: nil)
    }

    func enable(_ request: TealiumEnableRequest,
                diskStorage: TealiumDiskStorageProtocol? = nil) {
        config = request.config.copy
        // allows overriding for unit tests, independently of enable call
        if self.diskStorage == nil {
            self.diskStorage = diskStorage ?? TealiumDiskStorage(config: request.config, forModule: TealiumDispatchQueueConstants.moduleName)
        }
        persistentQueue = TealiumPersistentDispatchQueue(diskStorage: self.diskStorage)
        removeOldDispatches()
        isEnabled = true
        Tealium.lifecycleListeners.addDelegate(delegate: self)
        if !request.bypassDidFinish {
            didFinish(request)
        }
    }

    override func updateConfig(_ request: TealiumUpdateConfigRequest) {
        let newConfig = request.config.copy
        if newConfig != self.config {
            self.config = newConfig
            self.diskStorage = TealiumDiskStorage(config: request.config, forModule: TealiumDispatchQueueConstants.moduleName)
            persistentQueue = TealiumPersistentDispatchQueue(diskStorage: self.diskStorage)
        }
        didFinish(request)
    }

    override func handle(_ request: TealiumRequest) {
        switch request {
        case let request as TealiumEnableRequest:
            enable(request)
        case let request as TealiumDisableRequest:
            disable(request)
        case let request as TealiumTrackRequest:
            track(request)
        case let request as TealiumEnqueueRequest:
            queue(request)
        case let request as TealiumUpdateConfigRequest:
            updateConfig(request)
        case _ as TealiumReleaseQueuesRequest:
            releaseQueue()
        case _ as TealiumClearQueuesRequest:
            clearQueue()
        default:
            didFinishWithNoResponse(request)
        }
    }

    func queue(_ request: TealiumEnqueueRequest) {
        guard isEnabled else {
            return
        }
        removeOldDispatches()
        let allTrackRequests = request.data

        allTrackRequests.forEach {
            var newData = $0.trackDictionary
            newData[TealiumKey.wasQueued] = "true"
            let newTrack = TealiumTrackRequest(data: newData,
                                               completion: $0.completion)
            persistentQueue.appendDispatch(newTrack)
        }
    }

    func removeOldDispatches() {
        guard isEnabled else {
            return
        }
        let currentDate = Date()
        var components = DateComponents()
        components.calendar = Calendar.autoupdatingCurrent
        components.setValue(-batchExpirationDays, for: .day)
        let sinceDate = Calendar(identifier: .gregorian).date(byAdding: components, to: currentDate)
        persistentQueue.removeOldDispatches(maxQueueSize, since: sinceDate)
    }

    func releaseQueue() {
        // may be nil if module not yet enabled
        guard isEnabled else {
            return
        }

        if let queuedDispatches = persistentQueue.dequeueDispatches() {
            let batches: [[TealiumTrackRequest]] = queuedDispatches.chunks(maxDispatchSize)

            batches.forEach { batch in

                switch batch.count {
                case let val where val <= 1:
                    if var data = batch.first?.trackDictionary {
                        // for all release calls, bypass the queue and send immediately
                        data += ["bypass_queue": true]
                        let request = TealiumTrackRequest(data: data, completion: nil)
                            delegate?.tealiumModuleRequests(module: self,
                                                            process: request)
                    }

                case let val where val > 1:
                    let batchRequest = TealiumBatchTrackRequest(trackRequests: batch, completion: nil)
                        delegate?.tealiumModuleRequests(module: self,
                                                        process: batchRequest)
                default:
                    // should never reach here
                    return
                }

            }
        }
    }

    func clearQueue() {
        guard isEnabled else {
            return
        }
        persistentQueue.clearQueue()
    }

    // swiftlint:disable function_body_length
    override func track(_ request: TealiumTrackRequest) {
        defer {
            if persistentQueue.currentEvents >= self.eventsBeforeAutoDispatch,
                hasSufficientBattery(track: persistentQueue.peek()?.last) {
                releaseQueue()
            }
        }
        guard isEnabled else {
            didFinishWithNoResponse(request)
            return
        }

        let request = addModuleName(to: request)
        self.triggerRemoteAPIRequest(request)
        let canWrite = diskStorage.canWrite()
        var data = request.trackDictionary
        let newTrack = TealiumTrackRequest(data: data, completion: request.completion)
        guard canWrite else {
            let report = TealiumReportRequest(message: "Insufficient disk storage available. Event Batching has been disabled.")
            delegate?.tealiumModuleRequests(module: self, process: report)
            self.didFinishWithNoResponse(newTrack)
            return
        }
        guard hasSufficientBattery(track: request) else {
            enqueue(request, reason: "Insufficient Battery")
            return
        }
        var shouldBypass = false
        if data["bypass_queue"] as? Bool == true {
            shouldBypass = data.removeValue(forKey: "bypass_queue") as? Bool ?? false
        }
        guard isBatchingEnabled else {
            self.didFinishWithNoResponse(newTrack)
            return
        }

        guard eventsBeforeAutoDispatch > 1 else {
            didFinishWithNoResponse(newTrack)
            return
        }

        guard maxDispatchSize > 1 else {
            didFinishWithNoResponse(newTrack)
            return
        }

        guard maxQueueSize > 1 else {
            didFinishWithNoResponse(newTrack)
            return
        }

        guard canQueueRequest(newTrack) else {
            releaseQueue()
            didFinishWithNoResponse(newTrack)
            return
        }

        guard !shouldBypass else {
            didFinishWithNoResponse(newTrack)
            return
        }

        enqueue(request, reason: nil)
    }
    // swiftlint:enable function_body_length

    func hasSufficientBattery(track: TealiumTrackRequest?) -> Bool {
        guard let track = track else {
            return true
        }
        guard config?.batterySaverEnabled == true else {
            return true
        }
        guard let batteryPercentString = track.trackDictionary["battery_percent"] as? String, let batteryPercent = Double(batteryPercentString) else {
            return true
        }
        guard batteryPercent != -100 else {
            return true
        }
        guard batteryPercent >= 20.0 else {
            return false
        }
        return true
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

    func triggerRemoteAPIRequest(_ request: TealiumTrackRequest) {
        guard isRemoteAPIEnabled else {
            return
        }
        let request = TealiumRemoteAPIRequest(trackRequest: request)
        delegate?.tealiumModuleRequests(module: self, process: request)
    }

    func logQueue(request: TealiumTrackRequest) {
        let message = """
        \n=====================================
        ⏳ Event: \(request.trackDictionary[TealiumKey.event] as? String ?? "") queued for batch dispatch
        =====================================\n
        """
        let report = TealiumReportRequest(message: message)
        delegate?.tealiumModuleRequests(module: self, process: report)
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
