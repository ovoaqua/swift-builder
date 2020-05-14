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

    var config: TealiumConfig
    var originalConfig: TealiumConfig
    /// Mediator for all Tealium modules.
    var enableCompletion: TealiumEnableCompletion?
    public static var lifecycleListeners = TealiumLifecycleListeners()
    var remotePublishSettingsRetriever: TealiumPublishSettingsRetriever?
    public var eventDataManager: EventDataManagerProtocol
    public var zz_internal_modulesManager: ModulesManager?

    // MARK: PUBLIC

    /// Initializer.
    ///
    /// - Parameter config: `TealiumConfig` Object created with Tealium account, profile, environment, optional loglevel)
    /// - Parameter enableCompletion: `TealiumEnableCompletion` block to be called when library has finished initializing
    public init(config: TealiumConfig,
                eventDataManager: EventDataManagerProtocol? = nil,
                modulesManager: ModulesManager? = nil,
                enableCompletion: TealiumEnableCompletion?) {
        defer {
            TealiumQueues.backgroundConcurrentQueue.write {
                enableCompletion?(.success(true))
            }
        }
        self.config = config
        self.originalConfig = config.copy
        self.enableCompletion = enableCompletion
        self.eventDataManager = eventDataManager ?? EventDataManager(config: config)
        zz_internal_modulesManager = modulesManager ?? ModulesManager(config, eventDataManager: eventDataManager)
        if config.shouldUseRemotePublishSettings {
            self.remotePublishSettingsRetriever = TealiumPublishSettingsRetriever(config: config, delegate: self)
            if let remoteConfig = self.remotePublishSettingsRetriever?.cachedSettings?.newConfig(with: config) {
                self.config = remoteConfig
            }
        }
        TealiumQueues.backgroundConcurrentQueue.write { [weak self] in
            guard let self = self else {
                return
            }
            guard self.config.isEnabled == nil || self.config.isEnabled == true else {
                return
            }
            TealiumInstanceManager.shared.addInstance(self, config: config)
        }
        // TODO: Return any init errors here
    }

    /// - Parameter config: `TealiumConfig` Object created with Tealium account, profile, environment, optional loglevel)
    public convenience init(config: TealiumConfig) {
        self.init(config: config, enableCompletion: nil)
    }

    /// Update an actively running library with new configuration object.
    ///￼
    /// - Parameter config: TealiumConfiguration to update library with.
    public func update(config: TealiumConfig) {
        TealiumQueues.backgroundConcurrentQueue.write {
            self.zz_internal_modulesManager?.config = config
            self.config = config
        }
    }

    /// Suspends all library activity, may release internal objects.
    public func disable() {
        TealiumInstanceManager.shared.removeInstance(config: self.config)
        self.zz_internal_modulesManager = nil
    }

    /// Convenience track method with only a title argument.
    ///￼
    /// - Parameter title: String name of the event. This converts to 'tealium_event'
    public func track(title: String) {
        TealiumQueues.backgroundConcurrentQueue.write {
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
        TealiumQueues.backgroundConcurrentQueue.write { [weak self] in
            guard let self = self else {
                return
            }
            if self.config.shouldUseRemotePublishSettings {
                self.remotePublishSettingsRetriever?.refresh()
            }
            let trackData = Tealium.trackDataFor(title: title,
                                                 optionalData: data)
            self.eventDataManager.sessionRefresh()
            let track = TealiumTrackRequest(data: trackData,
                                            completion: completion)
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
        TealiumQueues.backgroundConcurrentQueue.write {
            var newData = [String: Any]()

            if let data = data {
                newData += data
            }

            newData[TealiumKey.callType] = TealiumTrackType.view.description()
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
    ///     - optionalData: Optional key-values for TIQ variables / UDH attributes
    ///     - Returns: Dictionary of type [String:Any]
    public class func trackDataFor(title: String,
                                   optionalData: [String: Any]?) -> [String: Any] {

        var trackData = optionalData ?? [String: Any]()
        trackData[TealiumKey.event] = title
        return trackData
    }
}

extension Tealium: TealiumPublishSettingsDelegate {
    func didUpdate(_ publishSettings: RemotePublishSettings) {
        let newConfig = publishSettings.newConfig(with: self.originalConfig)
        if newConfig != self.config {
            self.update(config: newConfig)
        }
    }
}
