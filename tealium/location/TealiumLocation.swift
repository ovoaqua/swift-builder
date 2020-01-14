//
//  TealiumLocation.swift
//  TealiumLocation
//
//  Created by Harry Cassell on 02/09/2019.
//  Updated by Christina Sund on 1/13/2020.
//  Copyright © 2019 Harry Cassell. All rights reserved.
//

import Foundation
import CoreLocation
//#if location
    import TealiumCore
//#endif

public class TealiumLocation: NSObject, CLLocationManagerDelegate {
    var config: TealiumConfig
    var locationManager: LocationManager
    var lastLocation: CLLocation?
    var geofences = Geofences()
    var locationListener: LocationListener?
   // var logger: TealiumLogger? include when merged w/1.8
    
    init(config: TealiumConfig,
        bundle: Bundle = Bundle.main,
        locationListener: LocationListener? = nil,
        locationManager: LocationManager = CLLocationManager()) {
        self.config = config
        // self.logger = TealiumLogger(loggerId: TealiumLocationKey.name, logLevel: config.getLogLevel())
        self.locationListener = locationListener
        self.locationManager = locationManager
        super.init() // Needs to be called here.
        
        switch config.initializeGeofenceDataFrom {
            case .localFile(let file):
                geofences = GeofenceData(file: file, bundle: bundle)?.geofences ?? Geofences()
            case .customUrl(let url):
                geofences = GeofenceData(url: url)?.geofences ?? Geofences()
            case .json(let jsonString):
                geofences = GeofenceData(json: jsonString)?.geofences ?? Geofences()
            default:
                geofences = GeofenceData(url: geofencesUrl(from: config))?.geofences ?? Geofences()
                break
        }
        
        
        self.locationManager.distanceFilter = config.updateDistance
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        requestPermissions()
        clearMonitoredGeofences()
        startLocationUpdates()
    }
    
    /// Gets the permission status of Location Services
    ///
    /// - return: `Bool` LocationManager services enabled true/false
    var locationServiceEnabled: Bool {
        let permissionStatus = type(of: locationManager).self.authorizationStatus()
        guard (permissionStatus == .authorizedAlways || permissionStatus == .authorizedWhenInUse),
            type(of: locationManager).self.locationServicesEnabled() else {
            return false
        }
        return true
    }
    
    /// Prompts the user to enable permission for location servies
    func requestPermissions() {
        let permissionStatus = type(of: locationManager).self.authorizationStatus()
        guard config.shouldRequestPermission else {
            return
        }
        if permissionStatus != .authorizedAlways {
            locationManager.requestAlwaysAuthorization()
        }
        
        if  permissionStatus != .authorizedWhenInUse {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    /// Enables regular updates of location data through the location client
    /// Update frequency is dependant on config.useHighAccuracy, a parameter passed on initisalizatuion of this class.
    func startLocationUpdates() {
        guard locationServiceEnabled else {
            // add logger
            return
        }
        guard config.useHighAccuracy else {
            locationManager.startMonitoringSignificantLocationChanges()
            // logger?.log(message: "🌎🌎 Location Updates Significant Location Change Accuracy Started 🌎🌎", logLevel: .verbose)
            return
        }
        locationManager.startUpdatingLocation()
        // logger?.log(message: "🌎🌎 Location Updates High Accuracy Started 🌎🌎", logLevel: .verbose)
    }
    
    /// Stops the updating of location data through the location client.
    func stopLocationUpdates() {
        guard locationServiceEnabled else {
            return
        }
        locationManager.stopUpdatingLocation()
        // logger?.log(message: "🌎🌎 Location Updates Stopped 🌎🌎", logLevel: .verbose)
    }
    
    /// Builds a URL from a Tealium config pointing to a hosted JSON file on the Tealium DLE
    ///
    /// - parameter config: `TealiumConfig` tealium config to be read from
    func geofencesUrl(from config: TealiumConfig) -> String {
        return "\(TealiumLocationKey.dleBaseUrl)\(config.account)/\(config.profile)/\(TealiumLocationKey.fileName).json"
    }
    
    /// CLLocationManagerDelegate method
    /// Updates a member variable containing the most recent device location alongisde
    /// updating the monitored geofences based on the users last location. (Dynamic Geofencing)
    ///
    /// - parameter manager: `CLLocationManager` instance
    /// - parameter locations: `CLLocation` array of recent locations, includes most recent
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let lastLocation = locations.last {
            self.lastLocation = lastLocation
        }
        // logger?.log(message: "🌎🌎 Location updated: \(String(describing: lastLocation?.coordinate)) 🌎🌎", logLevel: .verbose)
        geofences.regions.forEach {
            let geofenceLocation = CLLocation(latitude: $0.center.latitude, longitude: $0.center.longitude)
            
            guard let distance = lastLocation?.distance(from: geofenceLocation),
                distance.isLess(than: TealiumLocationKey.additionRange) else {
                stopMonitoring(geofence: $0)
                return
            }
            startMonitoring(geofence: $0)
        }
    }
    
    /// CLLocationManagerDelegate method
    /// If the location client encounters an error, location updates are stopped
    ///
    /// - parameter manager: `CLLocationManager` instance
    /// - parameter error: `error` an error that has occured
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let error = error as? CLError,
            error.code == .denied {
            // logger?.log(message: "🌎🌎 An error has occured: \(String(describing: error.localizedDescription)) 🌎🌎", logLevel: .errors)
            locationManager.stopUpdatingLocation()
        }
    }
    
    /// CLLocationManagerDelegate method
    /// Calls for the sending of a Tealium tracking call on geofence enter event
    ///
    /// - parameter manager: `CLLocationManager` instance
    /// - parameter region: `CLRegion` that was entered
    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        sendGeofenceTrackingEvent(region: region, triggeredTransition: TealiumLocationKey.entered)
    }
    
    /// CLLocationManagerDelegate method
    /// Calls for the sending of a Tealium tracking call on geofence exit event
    ///
    /// - parameter manager: `CLLocationManager` instance
    /// - parameter region: `CLRegion` that was entered
    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        sendGeofenceTrackingEvent(region: region, triggeredTransition: TealiumLocationKey.exited)
    }
    
    /// Sends a Tealium tracking event, appending geofence data to the track.
    ///
    /// - parameter region: `CLRegion` that was entered
    /// - parameter triggeredTransition: `String` Type of transition that occured
    func sendGeofenceTrackingEvent(region: CLRegion, triggeredTransition: String) {
        var data = [String : Any]()
        data[TealiumLocationKey.geofenceName] = "\(region.identifier)"
        data[TealiumLocationKey.geofenceTransition] = triggeredTransition
        data[TealiumKey.event] = triggeredTransition
        
        if let lastLocation = lastLocation {
            data[TealiumLocationKey.latitude] = "\(lastLocation.coordinate.latitude)"
            data[TealiumLocationKey.longitude] = "\(lastLocation.coordinate.longitude)"
            data[TealiumLocationKey.timestamp] = "\(lastLocation.timestamp)"
            data[TealiumLocationKey.speed] = "\(lastLocation.speed)"
        }
        
        if triggeredTransition == TealiumLocationKey.exited {
            locationListener?.didExitGeofence(data)
        } else if triggeredTransition == TealiumLocationKey.entered {
            locationListener?.didEnterGeofence(data)
        }
    }
    
    /// Gets the user's last known location
    ///
    /// - returns: `CLLocation` location object
    var latestLocation: CLLocation {
        guard let lastLocation = lastLocation else {
            return CLLocation.init()
        }
        return lastLocation
    }
    
    /// Adds geofences to the Location Client to be monitored
    ///
    /// - parameter geofences: `Array<CLCircularRegion>` Geofences to be added
    func startMonitoring(geofences: Array<CLCircularRegion>) {
        if geofences.capacity == 0 {
            return
        }
        
        geofences.forEach {
            if !(locationManager.monitoredRegions.contains($0)) {
                locationManager.startMonitoring(for: $0)
            }
        }
    }
    
    /// Adds geofences to the Location Client to be monitored
    ///
    /// - parameter geofence: `CLCircularRegion` Geofence to be added
    func startMonitoring(geofence: CLCircularRegion) {
        if !locationManager.monitoredRegions.contains(geofence) {
            locationManager.startMonitoring(for: geofence)
            // logger?.log(message: "🌎🌎 \(geofence.identifier) Added to monitored client 🌎🌎", logLevel: .verbose)
        }
    }
    
    /// Removes geofences from being monitored by the Location Client
    ///
    /// - parameter geofences: `Array<CLCircularRegion>` Geofences to be removed
    func stopMonitoring(geofences: Array<CLCircularRegion>) {
        if geofences.capacity == 0 {
            return
        }
        
        geofences.forEach {
            if locationManager.monitoredRegions.contains($0) {
                locationManager.stopMonitoring(for: $0)
            }
        }
    }
    
    /// Removes geofences from being monitored by the Location Client
    ///
    /// - parameter geofence: `CLCircularRegion` Geofence to be removed
    func stopMonitoring(geofence: CLCircularRegion) {
        if locationManager.monitoredRegions.contains(geofence) {
            locationManager.stopMonitoring(for: geofence)
            // logger?.log(message: "🌎🌎 \(geofence.identifier) Removed from monitored client 🌎🌎", logLevel: .verbose)
        }
    }

    /// Returns the names of all the geofences that are currently being monitored
    ///
    /// - return: `[String]` Array containing the names of monitored geofences
    var monitoredGeofences: [String]? {
        guard locationServiceEnabled else {
            return nil
        }
        return locationManager.monitoredRegions.map { $0.identifier }
    }
    
    /// Returns the names of all the created geofences (those currently being monitored and those that are not)
    ///
    /// - return: `[String]` Array containing the names of all geofences
    var createdGeofences: [String]? {
        guard locationServiceEnabled else {
            return nil
        }
        return geofences.map { $0.name }
    }
    
    /// Removes all geofences that are currently being monitored from the Location Client
    func clearMonitoredGeofences() {
        locationManager.monitoredRegions.forEach {
            locationManager.stopMonitoring(for: $0)
        }
    }
    
    /// Stops location updates, Removes all active geofences from being monitored,
    /// and resets the array of created geofences
    func disable() {
        stopLocationUpdates()
        clearMonitoredGeofences()
        self.geofences = Geofences()
    }

}

