//
//  TealiumLocationModule.swift
//  TealiumLocation
//
//  Created by Harry Cassell on 09/09/2019.
//  Updated by Christina Sund on 1/13/2020.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
//#if location
    import TealiumCore
//#endif

/// Module to add app related data to track calls.
class TealiumLocationModule: TealiumModule {

    var tealiumLocationManager: TealiumLocation!

    override class func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: "location",
            priority: 500,
            build: 3,
            enabled: true)
    }
    
    /// Enables the module and loads AppData into memory
    ///
    /// - Parameter request: TealiumEnableRequest - the request from the core library to enable this module
    override func enable(_ request: TealiumEnableRequest) {
        tealiumLocationManager = TealiumLocation(config: request.config, locationListener: self) // {
            isEnabled = true
            didFinishWithNoResponse(request)
       // }
    }

    /// Adds current AppData to the track request
    ///
    /// - Parameter track: TealiumTrackRequest to be modified
    override func track(_ track: TealiumTrackRequest) {
        guard isEnabled else {
            return didFinishWithNoResponse(track)
        }
        let location = tealiumLocationManager.latestLocation
        var newData: [String: Any] = [TealiumLocationKey.latitude: "\(location.coordinate.latitude)",
            TealiumLocationKey.longitude: "\(location.coordinate.longitude)"]
        newData.merge(track.trackDictionary) { $1 }
        let newTrack = TealiumTrackRequest(data: newData, completion: track.completion)
        didFinish(newTrack)
    }

    /// Disables the module and deletes all associated data
    ///
    /// - Parameter request: TealiumDisableRequest
    override func disable(_ request: TealiumDisableRequest) {
        guard isEnabled else {
            return didFinishWithNoResponse(request)
        }
        tealiumLocationManager.disable()
        didFinish(request)
    }
}

extension TealiumLocationModule: LocationListener {
    func didEnterGeofence(_ data: [String: Any]) {
        let trackRequest = TealiumTrackRequest(data: data, completion: nil)
        delegate?.tealiumModuleRequests(module: self, process: trackRequest)
    }

    func didExitGeofence(_ data: [String: Any]) {
        let trackRequest = TealiumTrackRequest(data: data, completion: nil)
        delegate?.tealiumModuleRequests(module: self, process: trackRequest)
    }
}
