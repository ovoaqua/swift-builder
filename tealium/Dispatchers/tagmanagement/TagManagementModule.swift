//
//  TagManagementModule.swift
//  TealiumCore
//
//  Created by Christina S on 4/28/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
//import TealiumCore


/// Dispatch Service Module for sending track data to the Tealium Webview.
public class TagManagementModule: Dispatcher {
    
    var config: TealiumConfig
    var errorState = AtomicInteger()
    var eventDataManager: EventDataManagerProtocol? // TODO:
    var pendingTrackRequests = [TealiumRequest]()
    var remoteCommandResponseObserver: NSObjectProtocol?
    var tagManagement: TealiumTagManagementProtocol?
    var webViewState: Atomic<TealiumWebViewState>?
    public var delegate: TealiumModuleDelegate
    public static var moduleId: String = "TagManagement"
    
    public required init(config: TealiumConfig,
                         delegate: TealiumModuleDelegate,
                         eventDataManager: EventDataManagerProtocol?) {
        self.config = config
        self.delegate = delegate
        self.eventDataManager = eventDataManager
        self.tagManagement = TealiumTagManagementWKWebView()
        enableNotifications()
        self.tagManagement?.enable(webviewURL: config.webviewURL, shouldMigrateCookies: true, delegates: config.webViewDelegates, shouldAddCookieObserver: config.shouldAddCookieObserver, view: config.rootView) { [weak self] _, error in
            guard let self = self else {
                return
            }

            TealiumQueues.backgroundConcurrentQueue.write { [weak self] in
                guard let self = self else {
                    return
                }
                if let error = error {
//                    let logger = TealiumLogger(loggerId: TealiumTagManagementModule.moduleConfig().name, logLevel: request.config.logLevel ?? TealiumLogLevel.errors)
//                    logger.log(message: (error.localizedDescription), logLevel: .warnings)
                    self.errorState.incrementAndGet()
                    self.webViewState?.value = .loadFailure
                } else {
                    self.errorState.resetToZero()
                    self.webViewState = Atomic(value: .loadSuccess)
                    self.flushQueue()
                }
            }
        }
    }
    
    /// Sends the track request to the webview.
    ///￼
    /// - Parameter track: `TealiumTrackRequest` to be sent to the webview
    func dispatchTrack(_ request: TealiumRequest) {
        switch request {
        case let track as TealiumBatchTrackRequest:
            let allTrackData = track.trackRequests.map {
                $0.trackDictionary
            }

            #if TEST
            #else
            self.tagManagement?.trackMultiple(allTrackData) { success, info, error in
                TealiumQueues.backgroundConcurrentQueue.write { [weak self] in
                    guard let self = self else {
                        return
                    }
                    track.completion?(success, info, error)
                    guard error == nil else {
//                        self.didFailToFinish(track, info: info, error: error!)
                        return
                    }
//                    self.didFinish(track,
//                                   info: info)
                }
            }
            #endif
        case let track as TealiumTrackRequest:
            #if TEST
            #else
            self.tagManagement?.track(track.trackDictionary) { success, info, error in
                TealiumQueues.backgroundConcurrentQueue.write { [weak self] in
                    guard let self = self else {
                        return
                    }
                    track.completion?(success, info, error)
                    guard error == nil else {
//                        self.didFailToFinish(track, info: info, error: error!)
                        return
                    }
//                    self.didFinish(track,
//                                   info: info)
                }
            }
            #endif
        default:
//            let reportRequest = TealiumReportRequest(message: "Unexpected request type received. Will not process.")
//            self.delegate?.tealiumModuleRequests(module: self, process: reportRequest)
            return
        }
    }
    
    /// Detects track type and dispatches appropriately.
    ///
    /// - Parameter track: `TealiumRequest`, which is expected to be either a `TealiumTrackRequest` or a `TealiumBatchTrackRequest`
    public func dynamicTrack(_ track: TealiumRequest) {
        if self.errorState.value > 0 {
            self.tagManagement?.reload { success, _, _ in
                if success {
                    self.errorState.value = 0
                    self.dynamicTrack(track)
                } else {
                    _ = self.errorState.incrementAndGet()
                    self.enqueue(track)
//                    let reportRequest = TealiumReportRequest(message: "WebView load failed. Will retry.")
//                    self.delegate?.tealiumModuleRequests(module: self, process: reportRequest)
                }
            }
            return
        } else if self.webViewState == nil || self.tagManagement?.isWebViewReady == false {
            self.enqueue(track)
//            self.didFailToFinish(track,
//                                 info: ["error_status": "Will retry when webview ready"],
//                                 error: TealiumTagManagementError.webViewNotYetReady)
            return
        }

        flushQueue()

        switch track {
        case let track as TealiumTrackRequest:
            self.dispatchTrack(prepareForDispatch(track))
        case let track as TealiumBatchTrackRequest:
            var newRequest = TealiumBatchTrackRequest(trackRequests: track.trackRequests.map { prepareForDispatch($0) },
                                                      completion: track.completion)
            newRequest.moduleResponses = track.moduleResponses
            self.dispatchTrack(newRequest)
        case let track as TealiumRemoteAPIRequest:
            self.dispatchTrack(prepareForDispatch(track.trackRequest))
//            let reportRequest = TealiumReportRequest(message: "Processing remote_api request.")
//            self.delegate?.tealiumModuleRequests(module: self, process: reportRequest)
            return
        default:
            //self.didFinishWithNoResponse(track)
            return
        }
    }
    
    /// Listens for notifications from the Remote Commands module. Typically these will be responses from a Remote Command that has finished executing.
    func enableNotifications() {
        remoteCommandResponseObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(TealiumKey.jsNotificationName), object: nil, queue: OperationQueue.main) { [weak self] notification in
            guard let self = self else {
                return
            }
            if let userInfo = notification.userInfo, let jsCommand = userInfo[TealiumKey.jsCommand] as? String {
                // Webview instance will ensure this is processed on the main thread
                self.tagManagement?.evaluateJavascript(jsCommand, nil)
            }
        }
    }
    
    /// Enqueues a request for later dispatch if the webview isn't ready.
    ///
    /// - Parameter request: `TealiumRequest` to be enqueued
    func enqueue(_ request: TealiumRequest) {
        guard request is TealiumTrackRequest || request is TealiumBatchTrackRequest else {
            return
        }

        switch request {
        case let request as TealiumBatchTrackRequest:
            var requests = request.trackRequests
            requests = requests.map {
                var trackData = $0.trackDictionary, track = $0
                trackData[TealiumKey.wasQueued] = true
                trackData[TealiumKey.queueReason] = "Tag Management Webview Not Ready"
                track.data = trackData.encodable
                return track
            }
            self.pendingTrackRequests.append(TealiumBatchTrackRequest(trackRequests: requests, completion: request.completion))
        case let request as TealiumTrackRequest:
            var track = request
            var trackData = track.trackDictionary
            trackData[TealiumKey.wasQueued] = true
            trackData[TealiumKey.queueReason] = "Tag Management Webview Not Ready"
            track.data = trackData.encodable
            self.pendingTrackRequests.append(track)
        default:
            return
        }
    }
    
    func flushQueue() {
        let pending = self.pendingTrackRequests
        self.pendingTrackRequests = []
        pending.forEach {
            self.dynamicTrack($0)
        }
    }
    
    /// Adds dispatch service key to the dispatch.
    ///
    /// - Parameter request: `TealiumTrackRequest` to be insepcted/modified
    /// - Returns: `TealiumTrackRequest`
    func prepareForDispatch(_ request: TealiumTrackRequest) -> TealiumTrackRequest {
        var newTrack = request.trackDictionary
        newTrack[TealiumKey.dispatchService] = TealiumTagManagementKey.moduleName

        if var eventDataManager = eventDataManager {
            if eventDataManager.sessionId == "" {
                eventDataManager.generateSessionId()
                eventDataManager.lastSessionIdRefresh = Date()
                eventDataManager.add(data: [TealiumKey.sessionId: eventDataManager.sessionId ?? "",
                                            TealiumKey.lastSessionIdRefresh: eventDataManager.lastSessionIdRefresh!],
                                     expiration: .session)
            }
            newTrack += eventDataManager.allEventData
        }

        var newRequest = TealiumTrackRequest(data: newTrack, completion: request.completion)
        newRequest.moduleResponses = request.moduleResponses
        return newRequest
    }

}
