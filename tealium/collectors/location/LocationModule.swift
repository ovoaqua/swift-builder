//
//  TealiumLocationModule.swift
//  TealiumLocation
//
//  Created by Harry Cassell on 09/09/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//
#if os(iOS)
import Foundation
#if location
import TealiumCore
#endif

/// Module to add app related data to track calls.
public class LocationModule: Collector {

    public let id: String = ModuleNames.location
    public var config: TealiumConfig
    weak var delegate: ModuleDelegate?
    var tealiumLocationManager: TealiumLocationManager?

    public var data: [String: Any]? {
        var newData = [String: Any]()
        guard let tealiumLocationManager = tealiumLocationManager else {
            return nil
        }
        let location = tealiumLocationManager.latestLocation
        if location.coordinate.latitude != 0.0 && location.coordinate.longitude != 0.0 {
            newData = [LocationKey.deviceLatitude: "\(location.coordinate.latitude)",
                LocationKey.deviceLongitude: "\(location.coordinate.longitude)",
                LocationKey.accuracy: tealiumLocationManager.locationAccuracy]
        }
        return newData
    }

    required public init(config: TealiumConfig, delegate: ModuleDelegate?, diskStorage: TealiumDiskStorageProtocol?, completion: (ModuleResult) -> Void) {
        self.config = config
        self.delegate = delegate

        if Thread.isMainThread {
            tealiumLocationManager = TealiumLocationManager(config: config, locationDelegate: self)
        } else {
            TealiumQueues.mainQueue.async {
                self.tealiumLocationManager = TealiumLocationManager(config: config, locationDelegate: self)
            }
        }

    }

    /// Disables the module and deletes all associated data
    func disable() {
        tealiumLocationManager?.disable()
    }

}

extension LocationModule: LocationDelegate {

    func didEnterGeofence(_ data: [String: Any]) {
        let trackRequest = TealiumTrackRequest(data: data, completion: nil)
        delegate?.requestTrack(trackRequest)
    }

    func didExitGeofence(_ data: [String: Any]) {
        let trackRequest = TealiumTrackRequest(data: data, completion: nil)
        delegate?.requestTrack(trackRequest)
    }
}
#endif
