//
//  NewModulesManager.swift
//  TealiumCore
//
//  Created by Craig Rouse on 21/04/2020.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

enum ModulesManagerLogMessages {
    static let system = "Modules Manager"
    static let modulesManagerInitialized = "Modules Manager Initialized"
    static let collectorsInitialized = "Collectors Initialized"
    static let dispatchValidatorsInitialized = "Dispatch Validators Initialized"
    static let dispatchersInitialized = "Dispatchers Initialized"
    static let noDispatchersEnabled = "No dispatchers are enabled. Please check remote publish settings."
    static let noConnectionDispatchersDisabled = "Internet connection not available. Dispatchers could not be enabled. Will retry when connection available."
    static let connectionLost = "Internet connection lost. Events will be queued until connection restored."
}

public class ModulesManager {
    // must store a copy of the initial config to allow locally-overridden properties to take precedence over remote ones. These would otherwise be lost after the first update.
    var originalConfig: TealiumConfig
    var remotePublishSettingsRetriever: TealiumPublishSettingsRetriever?
    var coreCollectors: [Collector.Type] = [TealiumAppDataModule.self, DeviceDataModule.self, TealiumConsentManagerModule.self]
    var optionalCollectors: [String] = TealiumValue.optionalCollectors
    var knownDispatchers: [String] = TealiumValue.knownDispatchers
    public var collectors = [Collector]()
    var dispatchValidators = [DispatchValidator]() {
        willSet {
            dispatchManager?.dispatchValidators = newValue
        }
    }
    var dispatchManager: DispatchManagerProtocol?
    var connectivityManager: TealiumConnectivity
    var dispatchers = [Dispatcher]() {
        willSet {
            self.dispatchManager?.dispatchers = newValue
        }
    }
    var dispatchListeners = [DispatchListener]() {
        willSet {
            self.dispatchManager?.dispatchListeners = newValue
        }
    }
    var eventDataManager: EventDataManagerProtocol?
    var logger: TealiumLoggerProtocol?
    public var modules: [TealiumModule] {
        get {
            self.collectors + self.dispatchers
        }

        set {
            let modules = newValue
            dispatchers = []
            collectors = []
            modules.forEach {
                switch $0 {
                case let module as Dispatcher:
                    addDispatcher(module)
                case let module as Collector:
                    addCollector(module)
                default:
                    return
                }
            }

        }
    }
    var config: TealiumConfig {
        willSet {
            self.dispatchManager?.config = newValue
            self.connectivityManager.config = newValue
            self.logger?.config = newValue
            self.updateConfig(config: newValue)
            self.modules.forEach {
                var module = $0
                module.config = newValue
            }
        }
    }

    init (_ config: TealiumConfig,
          eventDataManager: EventDataManagerProtocol?,
          optionalCollectors: [String]? = nil,
          knownDispatchers: [String]? = nil) {
        self.originalConfig = config.copy
        self.config = config
        self.connectivityManager = TealiumConnectivity(config: self.config, delegate: nil, diskStorage: nil) { _ in }
        self.eventDataManager = eventDataManager
        self.addCollector(connectivityManager)
        connectivityManager.addConnectivityDelegate(delegate: self)
        if config.shouldUseRemotePublishSettings {
            self.remotePublishSettingsRetriever = TealiumPublishSettingsRetriever(config: self.config, delegate: self)
            if let remoteConfig = self.remotePublishSettingsRetriever?.cachedSettings?.newConfig(with: self.config) {
                self.config = remoteConfig
            }
        }
        self.logger = self.config.logger
        self.setupDispatchers(config: self.config)
        self.setupDispatchValidators(config: self.config)
        self.setupDispatchListeners(config: self.config)

        self.dispatchManager = DispatchManager(dispatchers: self.dispatchers,
                                               dispatchValidators: self.dispatchValidators,
                                               dispatchListeners: self.dispatchListeners,
                                               connectivityManager: self.connectivityManager,
                                               config: self.config)
        self.setupCollectors(config: self.config)
        let logRequest = TealiumLogRequest(title: ModulesManagerLogMessages.modulesManagerInitialized, messages:
                                            ["\(ModulesManagerLogMessages.collectorsInitialized): \(self.collectors.map { $0.id })",
                                             "\(ModulesManagerLogMessages.dispatchValidatorsInitialized): \(self.dispatchValidators.map { $0.id })",
                                             "\(ModulesManagerLogMessages.dispatchersInitialized): \(self.dispatchers.map { $0.id })"
                                            ], info: nil, logLevel: .info, category: .`init`)
        self.logger?.log(logRequest)
    }

    func updateConfig(config: TealiumConfig) {
        if config.isCollectEnabled == false {
            disableModule(id: TealiumModuleNames.collect)
        }

        if config.isTagManagementEnabled == false {
            disableModule(id: TealiumModuleNames.tagmanagement)
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

        guard collectors.first(where: {
            type(of: $0) == type(of: collector)
        }) == nil else {
            return
        }
        collectors.append(collector)
    }

    func addDispatchListener(_ listener: DispatchListener) {
        guard dispatchListeners.first(where: {
            type(of: $0) == type(of: listener)
        }) == nil else {
            return
        }
        dispatchListeners.append(listener)
    }

    func addDispatchValidator(_ validator: DispatchValidator) {
        guard dispatchValidators.first(where: {
            type(of: $0) == type(of: validator)
        }) == nil else {
            return
        }
        dispatchValidators.append(validator)
    }

    func addDispatcher(_ dispatcher: Dispatcher) {
        guard dispatchers.first(where: {
            type(of: $0) == type(of: dispatcher)
        }) == nil else {
            return
        }
        dispatchers.append(dispatcher)
    }

    func setupCollectors(config: TealiumConfig) {
        coreCollectors.forEach { coreCollector in
            if coreCollector == TealiumConsentManagerModule.self && !config.enableConsentManager {
                return
            }
            let collector = coreCollector.init(config: config, delegate: self, diskStorage: nil) { _ in

            }

            addCollector(collector)
        }

        optionalCollectors.forEach { optionalCollector in
            guard let moduleRef = objc_getClass(optionalCollector) as? Collector.Type else {
                return
            }

            let collector = moduleRef.init(config: config, delegate: self, diskStorage: nil) { _ in

            }
            addCollector(collector)
        }
    }

    func setupDispatchers(config: TealiumConfig) {
        self.connectivityManager.checkIsConnected { [weak self] result in
            guard let self = self else {
                return
            }
            switch result {
            case .success:
                self.knownDispatchers.forEach { knownDispatcher in
                    guard let moduleRef = objc_getClass(knownDispatcher) as? Dispatcher.Type else {
                        return
                    }

                    if knownDispatcher.contains(TealiumModuleNames.tagmanagement),
                       config.isTagManagementEnabled == false {
                        return
                    } else {
                        self.eventDataManager?.tagManagementIsEnabled = true
                    }

                    if knownDispatcher.contains(TealiumModuleNames.collect),
                       config.isCollectEnabled == false {
                        return
                    }

                    let dispatcher = moduleRef.init(config: config, delegate: self) { result in
                        switch result.0 {
                        case .failure:
                            print("log error")
                        default:
                            break
                        }
                    }

                    self.addDispatcher(dispatcher)
                }
                if self.dispatchers.isEmpty {
                    let logRequest = TealiumLogRequest(title: ModulesManagerLogMessages.system,
                                                       message: ModulesManagerLogMessages.noDispatchersEnabled,
                                                       info: nil,
                                                       logLevel: .error,
                                                       category: .`init`)
                    self.logger?.log(logRequest)
                }
            case .failure:
                let logRequest = TealiumLogRequest(title: ModulesManagerLogMessages.system,
                                                   message: ModulesManagerLogMessages.noConnectionDispatchersDisabled,
                                                   info: nil,
                                                   logLevel: .error,
                                                   category: .`init`)
                self.logger?.log(logRequest)
                return
            }
        }

    }

    func setupDispatchValidators(config: TealiumConfig) {
        config.dispatchValidators?.forEach {
            self.addDispatchValidator($0)
        }
    }

    func setupDispatchListeners(config: TealiumConfig) {
        config.dispatchListeners?.forEach {
            self.addDispatchListener($0)
        }
    }

    func sendTrack(_ request: TealiumTrackRequest) {
        if self.config.shouldUseRemotePublishSettings == true {
            self.remotePublishSettingsRetriever?.refresh()
        }
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

        allData.value[TealiumKey.enabledModules] = modules.sorted { $0.id < $1.id }.map { $0.id }

        eventDataManager?.sessionRefresh()
        if let eventData = eventDataManager?.allEventData {
            allData.value += eventData
        }

        if let data = data {
            allData.value += data
        }
        return allData.value
    }

    func disableModule(id: String) {
        if let module = modules.first(where: { $0.id == id }) {
            switch module {
            case let module as Collector:
                self.collectors = self.collectors.filter { type(of: module) != type(of: $0) }
            case let module as Dispatcher:
                self.dispatchers = self.dispatchers.filter { type(of: module) != type(of: $0) }
            default:
                return
            }
        }
    }

    deinit {
        connectivityManager.removeAllConnectivityDelegates()
    }

}

extension ModulesManager: TealiumModuleDelegate {
    public func requestTrack(_ track: TealiumTrackRequest) {
        TealiumQueues.backgroundConcurrentQueue.write {
            self.sendTrack(track)
        }
    }

    public func requestDequeue(reason: String) {
        self.dispatchManager?.handleDequeueRequest(reason: reason)
    }

    public func processRemoteCommandRequest(_ request: TealiumRequest) {
        self.dispatchers.forEach {
            $0.dynamicTrack(request, completion: nil)
        }
    }
}

extension ModulesManager: TealiumConnectivityDelegate {
    public func connectionLost() {
        logger?.log(TealiumLogRequest(title: ModulesManagerLogMessages.system, message: ModulesManagerLogMessages.connectionLost, info: nil, logLevel: .info, category: .general))
    }

    public func connectionRestored() {
        if self.dispatchers.isEmpty {
            self.setupDispatchers(config: config)
        }
        self.requestDequeue(reason: TealiumConstants.connectionRestoredReason)
    }

}

extension ModulesManager: TealiumPublishSettingsDelegate {
    func didUpdate(_ publishSettings: RemotePublishSettings) {
        let newConfig = publishSettings.newConfig(with: self.originalConfig)
        if newConfig != self.config {
            self.config = newConfig
        }
    }
}
