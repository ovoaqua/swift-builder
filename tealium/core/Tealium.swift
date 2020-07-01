//
//  Tealium.swift
//  tealium-swift
//
//  Created by Jason Koo, Merritt Tidwell, Chad Hartman, Karen Tamayo, Chris Anderberg  on 8/31/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//
//

import Foundation

public typealias TealiumEnableCompletion = ((_ result: Result<Bool, Error>) -> Void)

///  Public interface for the Tealium library.
public class Tealium {

    var enableCompletion: TealiumEnableCompletion?
    public static var lifecycleListeners = TealiumLifecycleListeners()
    public var dataLayer: DataLayerManagerProtocol
    // swiftlint:disable identifier_name
    public var zz_internal_modulesManager: ModulesManager?
    // swiftlint:enable identifier_name

    // MARK: PUBLIC

    /// Initializer.
    ///
    /// - Parameter config: `TealiumConfig` Object created with Tealium account, profile, environment, optional loglevel)
    /// - Parameter enableCompletion: `TealiumEnableCompletion` block to be called when library has finished initializing
    public init(config: TealiumConfig,
                dataLayer: DataLayerManagerProtocol? = nil,
                modulesManager: ModulesManager? = nil,
                enableCompletion: TealiumEnableCompletion?) {
        defer {
            TealiumQueues.backgroundSerialQueue.async {
                enableCompletion?(.success(true))
            }
        }

        self.enableCompletion = enableCompletion
        self.dataLayer = dataLayer ?? DataLayer(config: config)

        TealiumQueues.backgroundSerialQueue.async {
            self.zz_internal_modulesManager = modulesManager ?? ModulesManager(config, dataLayer: self.dataLayer)
        }

        TealiumInstanceManager.shared.addInstance(self, config: config)
    }

    /// - Parameter config: `TealiumConfig` Object created with Tealium account, profile, environment, optional loglevel)
    public convenience init(config: TealiumConfig) {
        self.init(config: config, enableCompletion: nil)
    }

    /// Suspends all library activity, may release internal objects.
    public func disable() {
        TealiumQueues.backgroundSerialQueue.async {
            if let config = self.zz_internal_modulesManager?.config {
                TealiumInstanceManager.shared.removeInstance(config: config)
            }
            self.zz_internal_modulesManager = nil
        }
    }

    /// Convenience track method with only a title argument.
    ///￼
    /// - Parameter title: String name of the event. This converts to 'tealium_event'
    public func track(title: String) {
        TealiumQueues.backgroundSerialQueue.async {
            self.track(title: title,
                       data: nil,
                       completion: nil)
        }
    }

    /// Primary track method - equivalent to utag.track('link',{}) call.
    ///
    /// - Parameters:
    ///     - event Title: Required title of event.
    ///     - data: Optional dictionary for additional data sources to pass with call.
    ///     - completion: Optional callback that is returned IF a dispatch service has delivered a call. Note this callback will be returned for every dispatch service module enabled.
    ///     - successful: Wether completion succeeded or encountered a failure.
    ///     - info: Optional dictionary of data from call (ie encoded URL string, response headers, etc.).
    ///     - error: Error encountered, if any.
    public func track(title: String,
                      data: [String: Any]?,
                      completion: ((_ successful: Bool, _ info: [String: Any]?, _ error: Error?) -> Void)?) {
        let trackData = Tealium.trackDataFor(title: title,
                                             options: data)
        let track = TealiumTrackRequest(data: trackData,
                                        completion: completion)

        self.sendTrack(track)
    }

    /// Sends a track on the background queue
    /// Will not be executed until modules manager is ready (first work item in queue is to enable modules manager)
    func sendTrack(_ track: TealiumTrackRequest) {
        TealiumQueues.backgroundSerialQueue.async { [weak self] in
            guard let self = self else {
                return
            }

            self.zz_internal_modulesManager?.sendTrack(track)
        }
    }

    /// Track method for specifying view appearances - equivalent to a utag.track('view',{}) call.
    ///
    /// - Parameters:
    ///     - event Title: Required title of event.
    ///     - data: `[String: Any]?` for additional data sources to pass with call.
    ///     - completion: Optional callback that is returned IF a dispatch service has delivered a call. Note this callback will be returned for every dispatch service module enabled.
    ///     - successful: Whether completion succeeded or encountered a failure.
    ///     - info: Optional dictionary of data from call (ie encoded URL string, response headers, etc.).
    ///     - error: Error encountered, if any.
    public func trackView(title: String,
                          data: [String: Any]?,
                          completion: ((_ successful: Bool, _ info: [String: Any]?, _ error: Error?) -> Void)?) {
        TealiumQueues.backgroundSerialQueue.async {
            var newData = [String: Any]()

            if let data = data {
                newData += data
            }

            newData[TealiumKey.callType] = TealiumTrackType.view.description
            newData[TealiumKey.screenTitle] = title // added for backwards-compatibility

            self.track(title: title,
                       data: newData,
                       completion: completion)
        }
    }

    /// Packages a track title and any custom client data for Tealium track requests.
    ///     Calling this method directly generally not needed but could be used to
    ///     confirm the client added data payload that will be added to the Tealium
    ///     data layer prior to dispatch.
    ///
    /// - Parameters:
    ///     - type: TealiumTrackType to use.
    ///     - title: String description for track name.
    ///     - options: Optional key-values for TIQ variables / UDH attributes
    ///     - Returns: Dictionary of type [String:Any]
    public class func trackDataFor(title: String,
                                   options: [String: Any]?) -> [String: Any] {

        var trackData = options ?? [String: Any]()
        trackData[TealiumKey.event] = title
        return trackData
    }
}
