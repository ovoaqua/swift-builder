//
//  TealiumVisitorServiceManager.swift
//  tealium-swift
//
//  Created by Christina Sund on 5/13/19.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if visitorservice
import TealiumCore
#endif

public protocol TealiumVisitorServiceDelegate: class {
    func didUpdate(visitor profile: TealiumVisitorProfile)
}

enum VisitorServiceStatus: Int {
    case ready = 0
    case blocked = 1
}

public protocol TealiumVisitorServiceManagerProtocol {
    func startProfileUpdates(visitorId: String)
    func requestVisitorProfile()
}

public class TealiumVisitorServiceManager: TealiumVisitorServiceManagerProtocol {

    // private var visitorServiceDelegates = TealiumMulticastDelegate<TealiumVisitorServiceDelegate>()
    weak var delegate: TealiumVisitorServiceDelegate?
    var visitorServiceRetriever: TealiumVisitorServiceRetriever?
    var diskStorage: TealiumDiskStorageProtocol
    var timer: TealiumRepeatingTimer?
    var stateTimer: TealiumRepeatingTimer?
    var lifetimeEvents = 0.0
    var tealiumConfig: TealiumConfig
    var visitorId: String?
    var currentState: AtomicInteger = AtomicInteger(value: VisitorServiceStatus.ready.rawValue)
    var pollingAttempts: AtomicInteger = AtomicInteger(value: 0)
    var maxPollingAttempts = 5

    init(config: TealiumConfig,
         delegate: TealiumVisitorServiceDelegate?,
         diskStorage: TealiumDiskStorageProtocol) {
        tealiumConfig = config
        if let delegate = delegate {
            //for delegate in delegates {
                self.delegate = delegate
            //}
        }
        self.diskStorage = diskStorage
        guard let profile = diskStorage.retrieve(as: TealiumVisitorProfile.self) else {
                return
        }
        self.didUpdate(visitor: profile)
    }

    public func startProfileUpdates(visitorId: String) {
        self.visitorId = visitorId
        visitorServiceRetriever = visitorServiceRetriever ?? TealiumVisitorServiceRetriever(config: tealiumConfig, visitorId: visitorId)
        requestVisitorProfile()
    }

    public func requestVisitorProfile() {
        // No need to request if no delegates are listening
        guard delegate != nil else {
            return
        }

        guard currentState.value == VisitorServiceStatus.ready.rawValue,
            let _ = visitorId else {
            return
        }
        self.blockState()
        fetchProfile { profile, error in
            guard error == nil else {
                self.releaseState()
                return
            }
            guard let profile = profile else {
                self.startPolling()
                return
            }
            self.releaseState()
            self.diskStorage.save(profile, completion: nil)
            self.didUpdate(visitor: profile)
        }
    }

    func blockState() {
        currentState.value = VisitorServiceStatus.blocked.rawValue
        stateTimer = TealiumRepeatingTimer(timeInterval: 10.0)
        stateTimer?.eventHandler = { [weak self] in
               guard let self = self else {
                   return
               }
            self.releaseState()
            self.stateTimer?.suspend()
        }
        stateTimer?.resume()
    }

    func releaseState() {
        currentState.value = VisitorServiceStatus.ready.rawValue
    }

    func startPolling() {
        // No need to request if no delegates are listening
        guard delegate != nil else {
            return
        }
        if timer != nil {
            timer = nil
        }
        pollingAttempts.value = 0
        self.timer = TealiumRepeatingTimer(timeInterval: TealiumVisitorServiceConstants.pollingInterval)
        self.timer?.eventHandler = { [weak self] in
            guard let self = self else {
                return
            }
            self.fetchProfile { profile, error in
                guard error == nil else {
                    self.releaseState()
                    self.timer?.suspend()
                    return
                }
                guard let profile = profile else {
                    let attempts = self.pollingAttempts.incrementAndGet()
                    if attempts == self.maxPollingAttempts {
                        self.timer?.suspend()
                        self.pollingAttempts.resetToZero()
                    }
                    return
                }
                self.timer?.suspend()
                self.releaseState()
                self.diskStorage.save(profile, completion: nil)
                self.didUpdate(visitor: profile)
            }
        }
        self.timer?.resume()
    }

    func fetchProfile(completion: @escaping (TealiumVisitorProfile?, NetworkError?) -> Void) {
        // No need to request if no delegates are listening
        guard delegate != nil else {
            return
        }
        visitorServiceRetriever?.fetchVisitorProfile { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let profile):
                guard let profile = profile,
                    !profile.isEmpty else {
                    completion(nil, nil)
                    return
                }
                guard let lifetimeEventCount = profile.numbers?[TealiumVisitorServiceConstants.eventCountMetric],
                    self.lifetimeEventCountHasBeenUpdated(lifetimeEventCount) else {
                        completion(nil, nil)
                        return
                }
                completion(profile, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }

    /// Checks metric 22 (lifetime event count) within AudienceStream to see if the current value is greater than the previous.
    /// This will indicate whether or not the visitor profile has been updated since the last fetch.
    ///
    /// - Parameter count: `Double?` - Current value of the Lifetime Event Count (metric 22)
    /// - Returns: `Bool` `true` if lifetime event count has been updated
    func lifetimeEventCountHasBeenUpdated(_ count: Double?) -> Bool {
        guard let currentCount = count else {
            return false
        }
        let eventCountUpdated = currentCount > lifetimeEvents
        lifetimeEvents = currentCount
        return eventCountUpdated
    }
}

public extension TealiumVisitorServiceManager {

    /// Called when the visitor profile has been updated
    ///
    /// - Parameter profile: `TealiumVisitorProfile` - Updated visitor profile accessible through helper methods
    func didUpdate(visitor profile: TealiumVisitorProfile) {
        delegate?.didUpdate(visitor: profile)
    }

    /// - Returns: `TealiumVisitorProfile?` - the currrent cached profile from persistent storage.
    ///             As long as a previous fetch has been made, this should always return a profile, even if the device is offline
    func getCachedProfile(completion: @escaping (TealiumVisitorProfile?) -> Void) {
        completion(diskStorage.retrieve(as: TealiumVisitorProfile.self))
    }
}
