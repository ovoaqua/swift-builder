//
//  LifecycleModule.swift
//  TealiumSwift
//
//  Created by Christina S on 4/30/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

#if TEST
#else
#if os(OSX)
#else
import UIKit
#endif
#endif

#if lifecycle
import TealiumCore
#endif

public class LifecycleModule: Collector {

    public static var moduleId: String = "Lifecycle"
    var enabledPrior = false
    var lifecycleData = [String: Any]()
    var lifecycle: TealiumLifecycle?
    var lastProcess: TealiumLifecycleType?
    var lifecyclePersistentData: TealiumLifecyclePersistentData?
    var diskStorage: TealiumDiskStorageProtocol!
    var logger: TealiumLoggerProtocol

    public var data: [String: Any]? {
        lifecycle?.asDictionary(type: nil, for: Date())
    }

    public required init(config: TealiumConfig,
                         delegate: TealiumModuleDelegate,
                         diskStorage: TealiumDiskStorage?,
                         completion: () -> Void) {
        self.diskStorage = diskStorage ?? TealiumDiskStorage(config: config,
                                                             forModule: "lifecycle",
                                                             isCritical: true)
        self.logger = config.logger!
        self.lifecyclePersistentData = TealiumLifecyclePersistentData(diskStorage: self.diskStorage, uniqueId: nil)
        self.lifecycle = savedOrNewLifeycle
        save()
        if config.lifecycleAutoTrackingEnabled {
            Tealium.lifecycleListeners.addDelegate(delegate: self)
        }
    }
    
//    var lifecycle: TealiumLifecycle? {
//        get {
//            diskStorage.retrieve(as: TealiumLifecycle.self)
//        }
//        set {
//            if let newData = newValue {
//                diskStorage.save(newData, completion: nil)
//            }
//        }
//    }
    
    /// Determines if a lifecycle event should be triggered and requests a track.
    ///
    /// - Parameters:
    ///     - type: `TealiumLifecycleType`
    ///     - date: `Date` at which the event occurred
    public func process(type: TealiumLifecycleType,
        at date: Date) {

        // If lifecycle has been nil'd out - module not ready or has been disabled
        guard var lifecycle = self.lifecycle else { return }

        // Setup data to be used in switch statement
        //var data: [String: Any]

        // Update internal model and retrieve data for a track call
        switch type {
        case .launch:
            if enabledPrior == true { return }
            enabledPrior = true
            lifecycleData += lifecycle.newLaunch(at: date,
                overrideSession: nil)
        case .sleep:
            lifecycleData += lifecycle.newSleep(at: date)
        case .wake:
            lifecycleData += lifecycle.newWake(at: date,
                overrideSession: nil)
        }
        self.lifecycle = lifecycle
        let req = TealiumLogRequest(title: "⏫Lifecycle", message: "", info: lifecycleData, logLevel: .info, category: .general)
        logger.log(req)
        // Save now in case we crash later
        save()
    }
    
    /// Prevent manual spanning of repeated lifecycle calls to system.
    ///
    /// - Parameter type: `TealiumLifecycleType`
    /// - Returns: `Bool` `true` if process should be allowed to continue
    public func processAcceptable(type: TealiumLifecycleType) -> Bool {
        guard let lastProcess = lastProcess else {
            return false
        }
        switch type {
        case .launch:
            // Can only occur once per app lifecycle
            if enabledPrior == true {
                return false
            }
        case .sleep:
            if lastProcess != .wake && lastProcess != .launch {
                return false
            }
        case .wake:
            if lastProcess != .sleep {
                return false
            }
        }
        return true
    }

    public func processDetected(type: TealiumLifecycleType,
        at date: Date = Date()) {
        guard processAcceptable(type: type) else {
            return
        }

        lastProcess = type
        self.process(type: type, at: date)
    }

    /// Attempts to load lifecycle data from persistent storage, or returns new lifecycle data if not found.
    ///
    /// - Returns: `TealiumLifecycle`
    public var savedOrNewLifeycle: TealiumLifecycle {
        // Attempt to load first
        if let loadedLifecycle = load() {
            return loadedLifecycle
        }
        return TealiumLifecycle()
    }

    /// Saves current lifecycle data to persistent storage.
    public func save() {
        guard let lifecycle = self.lifecycle else {
            return
        }
        diskStorage.save(lifecycle, completion: nil)
    }

    public func load() -> TealiumLifecycle? {
        return diskStorage.retrieve(as: TealiumLifecycle.self)
    }

}

extension LifecycleModule: TealiumLifecycleEvents {
    public func sleep() {
        processDetected(type: .sleep)
    }

    public func wake() {
        processDetected(type: .wake)
    }

    public func launch(at date: Date) {
        processDetected(type: .launch, at: date)
    }
}


