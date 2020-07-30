//
//  MockTealiumLocationManager.swift
//  TealiumLocationTests-iOS
//
//  Created by Christina S on 7/28/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import CoreLocation
import Foundation
@testable import TealiumLocation

class MockTealiumLocaitonManager: TealiumLocationManagerProtocol {

    var createdGeofencesCallCount = 0
    var latestLocationCallCount = 0
    var locationAccuracyCallCount = 0
    var locationServiceEnabledCallCount = 0
    var monitoredGeofencesCallCount = 0
    var clearMonitoredGeofencesCallCount = 0
    var disableCallCount = 0
    var requestPermissionsCallCount = 0
    var sendGeofenceTrackingEventCallCount = 0
    var startLocationUpdatesCallCount = 0
    var startMonitoringCallCount = 0
    var stopLocationUpdatesCallCount = 0
    var stopMonitoringCallCount = 0

    var createdGeofences: [String]? {
        createdGeofencesCallCount += 1
        return ["geofence"]
    }

    var latestLocation: CLLocation {
        latestLocationCallCount += 1
        return CLLocation()
    }

    var locationAccuracy: String {
        get {
            locationAccuracyCallCount += 1
            return "locationAccuracy"
        }
        set {

        }
    }

    var locationServiceEnabled: Bool {
        locationServiceEnabledCallCount += 1
        return true
    }

    var monitoredGeofences: [String]? {
        monitoredGeofencesCallCount += 1
        return ["monitoredGeofences"]
    }

    func clearMonitoredGeofences() {
        clearMonitoredGeofencesCallCount += 1
    }

    func disable() {
        disableCallCount += 1
    }

    func requestPermissions() {
        requestPermissionsCallCount += 1
    }

    func sendGeofenceTrackingEvent(region: CLRegion, triggeredTransition: String) {
        sendGeofenceTrackingEventCallCount += 1
    }

    func startLocationUpdates() {
        startLocationUpdatesCallCount += 1
    }

    func startMonitoring(_ geofences: [CLCircularRegion]) {
        startMonitoringCallCount += 1
    }

    func stopLocationUpdates() {
        stopLocationUpdatesCallCount += 1
    }

    func stopMonitoring(_ geofences: [CLCircularRegion]) {
        stopMonitoringCallCount += 1
    }

}