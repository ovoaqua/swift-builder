//
//  CollectModule.swift
//  TealiumCore
//
//  Created by Craig Rouse on 24/04/2020.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumCore

/// Dispatch Service Module for sending track data to the Tealium Collect or custom endpoint.
public class CollectModule: Dispatcher {
    
    public static var moduleId: String = "Collect"
    var collect: TealiumCollectProtocol?
    public var delegate: TealiumModuleDelegate
    var eventDataManager: EventDataManagerProtocol? // TODO:
    var config: TealiumConfig
    
    required public init(config: TealiumConfig,
                         delegate: TealiumModuleDelegate,
                         eventDataManager: EventDataManagerProtocol?) {
        self.config = config
        self.delegate = delegate
        self.eventDataManager = eventDataManager
        updateCollectDispatcher(config: config, completion: nil)
    }

    func updateCollectDispatcher(config: TealiumConfig,
                                 completion: ((_ success: Bool, _ error: TealiumCollectError) -> Void)?) {
        let urlString = config.optionalData[TealiumCollectKey.overrideCollectUrl] as? String ?? TealiumCollectPostDispatcher.defaultDispatchBaseURL
        collect = TealiumCollectPostDispatcher(dispatchURL: urlString, completion: completion)
    }

    /// Detects track type and dispatches appropriately, adding mandatory data (account and profile) to the track if missing.￼
    ///
    /// - Parameter track: `TealiumRequest`, which is expected to be either a `TealiumTrackRequest` or a `TealiumBatchTrackRequest`
    public func dynamicTrack(_ request: TealiumRequest) {
        guard collect != nil else {
//            didFailToFinish(track,
//                            error: TealiumCollectError.collectNotInitialized)
            return
        }

        switch request {
        case let request as TealiumTrackRequest:
            guard request.trackDictionary[TealiumKey.event] as? String != TealiumKey.updateConsentCookieEventName else {
//                didFinishWithNoResponse(track)
                return
            }
            self.track(prepareForDispatch(request))
        case let request as TealiumBatchTrackRequest:
            var requests = request.trackRequests
            requests = requests.filter {
                $0.trackDictionary[TealiumKey.event] as? String != TealiumKey.updateConsentCookieEventName
            }.map {
                prepareForDispatch($0)
            }
            var newRequest = TealiumBatchTrackRequest(trackRequests: requests, completion: request.completion)
            newRequest.moduleResponses = request.moduleResponses
            self.batchTrack(newRequest)
        default:
//            self.didFinishWithNoResponse(track)
            return
        }
    }

    /// Adds required account information to the dispatch if missing￼.
    ///
    /// - Parameter request: `TealiumTrackRequest` to be insepcted/modified
    /// - Returns: `TealiumTrackRequest`
    func prepareForDispatch(_ request: TealiumTrackRequest) -> TealiumTrackRequest {
//        let request = addModuleName(to: request)
        var newTrack = request.trackDictionary
        if newTrack[TealiumKey.account] == nil,
            newTrack[TealiumKey.profile] == nil {
            newTrack[TealiumKey.account] = config.account
            newTrack[TealiumKey.profile] = config.profile
        }

        if let profileOverride = config.optionalData[TealiumCollectKey.overrideCollectProfile] as? String {
            newTrack[TealiumKey.profile] = profileOverride
        }

        newTrack[TealiumKey.dispatchService] = TealiumCollectKey.moduleName
        return TealiumTrackRequest(data: newTrack, completion: request.completion)
    }

    /// Adds relevant info to the track request, then passes the request to a dipatcher for processing￼.
    ///
    /// - Parameter track: `TealiumTrackRequest` to be dispatched
    func track(_ track: TealiumTrackRequest) {
        guard let collect = collect else {
//            didFinishWithNoResponse(track)
            return
        }

        // Send the current track call
        let data = track.trackDictionary

        collect.dispatch(data: data, completion: { success, info, error in

            track.completion?(success, info, error)

            // Let the modules manager know we had a failure.
            guard success else {
//                let localError = error ?? TealiumCollectError.unknownIssueWithSend
//                self.didFailToFinish(track,
//                                     info: info,
//                                     error: localError)
                return
            }

            var trackInfo = info ?? [String: Any]()
            trackInfo += [TealiumCollectKey.payload: track.trackDictionary]

            // Another message to moduleManager of completed track, this time of
            //  modified track data.
//            self.didFinish(track,
//                           info: trackInfo)
        })
    }

    /// Adds relevant info to the track request, then passes the request to a dipatcher for processing￼.
    ///
    /// - Parameter track: `TealiumBatchTrackRequest` to be dispatched
    func batchTrack(_ request: TealiumBatchTrackRequest) {
        guard let collect = collect else {
//            didFinishWithNoResponse(request)
            return
        }

        guard let compressed = request.compressed() else {
            let logRequest = TealiumReportRequest(message: "Batch track request failed. Will not be sent.")
            delegate.tealiumModuleRequests(module: nil, process: logRequest)
            return
        }

        collect.dispatchBulk(data: compressed) { success, info, error in

//            guard success else {
//                let localError = error ?? TealiumCollectError.unknownIssueWithSend
//                self.didFailToFinish(request,
//                                     info: info,
//                                     error: localError)
//                let logRequest = TealiumReportRequest(message: "Batch track request failed. Error: \(error?.localizedDescription ?? "unknown")")
//                self.delegate?.tealiumModuleRequests(module: nil, process: logRequest)
//                return
//            }

//            self.didFinish(request, info: info)
        }
    }

//    /// Called when the module failed for to complete a request￼.
//    ///
//    /// - Parameters:
//    ///     - request: `TealiumRequest` that failed￼
//    ///     - info: `[String: Any]? `containing information about the failure￼
//    ///     - error: `Error` with precise information about the failure
//    func didFailToFinish(_ request: TealiumRequest,
//                         info: [String: Any]?,
//                         error: Error) {
//        var newRequest = request
//        var response = TealiumModuleResponse(moduleName: type(of: self).moduleConfig().name,
//                                             success: false,
//                                             error: error)
//        if let error = error as? URLError,
//        error.code == URLError.notConnectedToInternet || error.code == URLError.networkConnectionLost || error.code == URLError.timedOut {
//
//            switch request {
//            case let request as TealiumTrackRequest:
//                let enqueueRequest = TealiumEnqueueRequest(data: request, queueReason: "connectivity", completion: nil)
//                delegate?.tealiumModuleRequests(module: self, process: enqueueRequest)
//            case let request as TealiumBatchTrackRequest:
//                let enqueueRequest = TealiumEnqueueRequest(data: request, queueReason: "connectivity", completion: nil)
//                delegate?.tealiumModuleRequests(module: self, process: enqueueRequest)
//            default:
//                return
//            }
//
//            let connectivityRequest = TealiumConnectivityRequest(status: .notReachable)
//            delegate?.tealiumModuleRequests(module: self, process: connectivityRequest)
//        } else {
//            response.info = info
//            newRequest.moduleResponses.append(response)
//            delegate?.tealiumModuleFinished(module: self,
//                                            process: newRequest)
//        }
//    }
//
//    /// Disables the module￼.
//    ///
//    /// - Parameter request: `TealiumDisableRequest`
//    override func disable(_ request: TealiumDisableRequest) {
//        isEnabled = false
//        self.collect = nil
//        didFinish(request)
//    }

}
