//
//  TealiumLocationModule.swift
//  TealiumLocation
//
//  Created by Harry Cassell on 09/09/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//
#if os(iOS)
import CoreLocation
import Foundation
#if location
import TealiumCore
#endif

/// Module to add app related data to track calls.
public class LocationModule: Collector {

    public let id: String = ModuleNames.location
    public var config: TealiumConfig
    weak var delegate: ModuleDelegate?
    var tealLocationManager: TealiumLocationManagerProtocol?

    public var data: [String: Any]? {
        var newData = [String: Any]()
        guard let tealLocationManager = tealLocationManager else {
            return nil
        }
        let location = tealLocationManager.latestLocation
        if location.coordinate.latitude != 0.0 && location.coordinate.longitude != 0.0 {
            newData = [LocationKey.deviceLatitude: "\(location.coordinate.latitude)",
                LocationKey.deviceLongitude: "\(location.coordinate.longitude)",
                LocationKey.accuracy: tealLocationManager.locationAccuracy]
        }
        return newData
    }

    required public init(config: TealiumConfig, delegate: ModuleDelegate?, diskStorage: TealiumDiskStorageProtocol?, completion: (ModuleResult) -> Void) {
        self.config = config
        self.delegate = delegate

        if Thread.isMainThread {
            tealLocationManager = TealiumLocationManager(config: config, locationDelegate: self)
        } else {
            TealiumQueues.mainQueue.async { [weak self] in
                guard let self = self else {
                    return
                }
                self.tealLocationManager = TealiumLocationManager(config: config, locationDelegate: self)
            }
        }

    }

    /// Removes all geofences that are currently being monitored from the Location Client
    public func clearMonitoredGeofences() {
        TealiumQueues.mainQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.tealLocationManager?.clearMonitoredGeofences()
        }
    }

    /// Returns the names of all the created geofences (those currently being monitored and those that are not)
    ///
    /// - return: `[String]` Array containing the names of all geofences
    public var createdGeofences: [String]? {
        var created: [String]?
        TealiumQueues.mainQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            created = self.tealLocationManager?.createdGeofences
        }
        return created
    }

    /// Disables the module and deletes all associated data
    func disable() {
        TealiumQueues.mainQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.tealLocationManager?.disable()
        }

    }

    /// Gets the user's last known location
    ///
    /// - returns: `CLLocation` location object
    public var latestLocation: CLLocation? {
        var latest: CLLocation?
        TealiumQueues.mainQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            latest = self.tealLocationManager?.latestLocation
        }
        return latest
    }

    /// Gets the permission status of Location Services
    ///
    /// - return: `Bool` LocationManager services enabled true/false
    public var locationServiceEnabled: Bool {
        var enabled = false
        TealiumQueues.mainQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            enabled = self.tealLocationManager?.locationServiceEnabled ?? false
        }
        return enabled
    }

    /// Returns the names of all the geofences that are currently being monitored
    ///
    /// - return: `[String]` Array containing the names of monitored geofences
    public var monitoredGeofences: [String]? {
        var monitored: [String]?
        TealiumQueues.mainQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            monitored = self.tealLocationManager?.monitoredGeofences
        }
        return monitored
    }

    /// Sends a Tealium tracking event, appending geofence data to the track.
    ///
    /// - parameter region: `CLRegion` that was entered
    /// - parameter triggeredTransition: `String` Type of transition that occured
    public func sendGeofenceTrackingEvent(region: CLRegion, triggeredTransition: String) {
        TealiumQueues.mainQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.tealLocationManager?.sendGeofenceTrackingEvent(region: region, triggeredTransition: triggeredTransition)
        }
    }

    /// Enables regular updates of location data through the location client
    /// Update frequency is dependant on config.useHighAccuracy, a parameter passed on initisalizatuion of this class.
    public func startLocationUpdates() {
        TealiumQueues.mainQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.tealLocationManager?.startLocationUpdates()
        }
    }

    /// Stops the updating of location data through the location client.
    public func stopLocationUpdates() {
        TealiumQueues.mainQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.tealLocationManager?.stopLocationUpdates()
        }
    }

    /// Adds geofences to the Location Client to be monitored
    ///
    /// - parameter geofences: `Array<CLCircularRegion>` Geofences to be added
    public func startMonitoring(geofences: [CLCircularRegion]) {
        TealiumQueues.mainQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.tealLocationManager?.startMonitoring(geofences)
        }
    }

    /// Removes geofences from being monitored by the Location Client
    ///
    /// - parameter geofences: `Array<CLCircularRegion>` Geofences to be removed
    public func stopMonitoring(geofences: [CLCircularRegion]) {
        TealiumQueues.mainQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.tealLocationManager?.stopMonitoring(geofences)
        }
    }

    /// Prompts the user to enable permission for location servies
    public func requestPermissions() {
        TealiumQueues.mainQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.tealLocationManager?.requestPermissions()
        }
    }

}

extension LocationModule: LocationDelegate {

    func didEnterGeofence(_ data: [String: Any]) {
        let trackRequest = TealiumTrackRequest(data: data)
        delegate?.requestTrack(trackRequest)
    }

    func didExitGeofence(_ data: [String: Any]) {
        let trackRequest = TealiumTrackRequest(data: data)
        delegate?.requestTrack(trackRequest)
    }
}
#endif
