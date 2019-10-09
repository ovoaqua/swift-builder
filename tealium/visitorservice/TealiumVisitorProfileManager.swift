//
//  TealiumVisitorProfileManager.swift
//  tealium-swift
//
//  Created by Christina Sund on 5/13/19.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if visitorservice
import TealiumCore
#endif

public protocol TealiumVisitorProfileDelegate: class {
    func profileDidUpdate(profile: TealiumVisitorProfile?)
}

enum VisitorProfileStatus: Int {
    case ready = 0
    case blocked = 1
}

public protocol TealiumVisitorProfileManagerProtocol {
    func startProfileUpdates(visitorId: String)
    func requestVisitorProfile()
}

public class TealiumVisitorProfileManager: TealiumVisitorProfileManagerProtocol {

    private var visitorProfileDelegates = TealiumMulticastDelegate<TealiumVisitorProfileDelegate>()
    var visitorProfileRetriever: TealiumVisitorProfileRetriever?
    var diskStorage: TealiumDiskStorageProtocol
    var timer: TealiumRepeatingTimer?
    var stateTimer: TealiumRepeatingTimer?
    var lifetimeEvents = 0.0
    var tealiumConfig: TealiumConfig
    var visitorId: String?
    var currentState: AtomicInteger = AtomicInteger(value: VisitorProfileStatus.ready.rawValue)
    var pollingAttempts: AtomicInteger = AtomicInteger(value: 0)
    var maxPollingAttempts = 5

    init(config: TealiumConfig,
         delegates: [TealiumVisitorProfileDelegate]?,
         diskStorage: TealiumDiskStorageProtocol) {
        tealiumConfig = config
        if let delegates = delegates {
            for delegate in delegates {
                self.visitorProfileDelegates.add(delegate)
            }
        }
        self.diskStorage = diskStorage
        diskStorage.retrieve(as: TealiumVisitorProfile.self) { _, profile, _ in
            guard let profile = profile else {
                return
            }
            self.profileDidUpdate(profile: profile)
        }
    }

    public func startProfileUpdates(visitorId: String) {
        self.visitorId = visitorId
        visitorProfileRetriever = visitorProfileRetriever ?? TealiumVisitorProfileRetriever(config: tealiumConfig, visitorId: visitorId)
        requestVisitorProfile()
    }

    public func requestVisitorProfile() {
        guard currentState.value == VisitorProfileStatus.ready.rawValue,
            let _ = visitorId else {
            return
        }
        self.blockState()
        fetchProfile { profile in
            guard let profile = profile else {
                self.startPolling()
                return
            }
            self.releaseState()
            self.diskStorage.save(profile, completion: nil)
            self.profileDidUpdate(profile: profile)
        }
    }

    func blockState() {
        currentState.value = VisitorProfileStatus.blocked.rawValue
        stateTimer = TealiumRepeatingTimer(timeInterval: 10.0)
        stateTimer?.eventHandler = {
            self.releaseState()
            self.stateTimer?.suspend()
        }
        stateTimer?.resume()
    }

    func releaseState() {
        currentState.value = VisitorProfileStatus.ready.rawValue
    }

    func startPolling() {
        if timer != nil {
            timer = nil
        }
        pollingAttempts.value = 0
        self.timer = TealiumRepeatingTimer(timeInterval: TealiumVisitorProfileConstants.pollingInterval)
        self.timer?.eventHandler = {
            self.fetchProfile { profile in
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
                self.profileDidUpdate(profile: profile)
            }
        }
        self.timer?.resume()
    }

    func fetchProfile(completion: @escaping (TealiumVisitorProfile?) -> Void) {

        visitorProfileRetriever?.fetchVisitorProfile { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let profile):
                guard let profile = profile,
                    !profile.isEmpty else {
                    completion(nil)
                    return
                }
                guard let lifetimeEventCount = profile.numbers?[TealiumVisitorProfileConstants.eventCountMetric],
                    self.lifetimeEventCountHasBeenUpdated(lifetimeEventCount) else {
                        completion(nil)
                        return
                }
                completion(profile)
            case .failure:
                completion(nil)
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

// MARK: Invoke delegate methods
extension TealiumVisitorProfileManager {

    /// Called when the visitor profile has been updated
    ///
    /// - Parameter profile: `TealiumVisitorProfile` - Updated visitor profile accessible through helper methods
    func profileDidUpdate(profile: TealiumVisitorProfile) {
        visitorProfileDelegates.invoke {
            $0.profileDidUpdate(profile: profile)
        }
    }
}

public extension TealiumVisitorProfileManager {

    /// Adds a new class conforming to `VisitorProfileDelegate`
    ///
    /// - Parameter delegate: Class conforming to `VisitorProfileDelegate` to be added
    func addVisitorProfileDelegate(_ delegate: TealiumVisitorProfileDelegate) {
        visitorProfileDelegates.add(delegate)
    }

    /// Removes all visitor profile delegates except the visitor profile module itself.
    func removeAllVisitorProfileDelegates() {
        visitorProfileDelegates.removeAll()
    }

    /// Removes a specific visitor profile delegate.
    ///
    /// - Parameter delegate: Class conforming to `VisitorProfileDelegate` to be removed
    func removeSingleDelegate(delegate: TealiumVisitorProfileDelegate) {
        visitorProfileDelegates.remove(delegate)
    }

    /// - Returns: `TealiumVisitorProfile?` - the currrent cached profile from persistent storage.
    ///             As long as a previous fetch has been made, this should always return a profile, even if the device is offline
    func getCachedProfile(completion: @escaping (TealiumVisitorProfile?) -> Void) {
        diskStorage.retrieve(as: TealiumVisitorProfile.self) { _, data, _ in
            completion(data)
        }
    }
}
