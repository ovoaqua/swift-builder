//
//  TealiumLocationExtensions.swift
//  TealiumLocation
//
//  Created by Harry Cassell on 12/09/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//
#if os(iOS)
import Foundation
#if location
import TealiumCore
#endif

// MARK: EXTENSIONS
extension Tealium {

    /// Returns a LocationManager instance
    ///
    /// - Returns: `TealiumLocation?` instance (nil if disabled)
    var location: TealiumLocation? {
        let module = (zz_internal_modulesManager?.modules.first { $0 is LocationModule }) as? LocationModule

        return module?.tealiumLocationManager
    }
}

public extension Collectors {
    static let Location = LocationModule.self
}

public extension TealiumConfig {

    /// The desired location accuracy
    ///
    ///
    /// - `Bool` true if more frequent location updates are wanted,
    /// or false if only significant location updates are desired (more battery friendly)
    var useHighAccuracy: Bool {
        get {
            options[TealiumLocationConfigKey.useHighAccuracy] as? Bool ?? false
        }

        set {
            options[TealiumLocationConfigKey.useHighAccuracy] = newValue
        }
    }

    /// The distance at which location updates should be received, e.g. 500.0 for every 500 meters
    ///
    ///
    /// - `Double` distance in meters
    var updateDistance: Double {
        get {
            options[TealiumLocationConfigKey.updateDistance] as? Double ?? 500.0
        }

        set {
            options[TealiumLocationConfigKey.updateDistance] = newValue
        }
    }

    /// The name of the local file to be read that contains geofence json data
    ///
    ///
    /// - `String` name of local file to read
    var geofenceFileName: String? {
        get {
            options[TealiumLocationConfigKey.geofenceAssetName] as? String
        }

        set {
            options[TealiumLocationConfigKey.geofenceAssetName] = newValue
        }
    }

    /// The url to be read that contains geofence json data
    ///
    ///
    /// - `String` name of the url to read
    var geofenceUrl: String? {
        get {
            options[TealiumLocationConfigKey.geofenceJsonUrl] as? String
        }

        set {
            options[TealiumLocationConfigKey.geofenceJsonUrl] = newValue
        }
    }

    /// `TealiumLocationConfig`: The Geofences data retrieved from either a local file, url, or DLE
    var initializeGeofenceDataFrom: TealiumLocationConfig {
        if let geofenceAsset = self.geofenceFileName {
            return .localFile(geofenceAsset)
        } else if let geofenceUrl = self.geofenceUrl {
            return .customUrl(geofenceUrl)
        }
        return .tealium
    }
}
#endif
