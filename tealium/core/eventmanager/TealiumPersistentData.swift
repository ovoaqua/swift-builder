//
//  TealiumPersistentData.swift
//  ios
//
//  Created by Craig Rouse on 11/07/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

public class TealiumPersistentData {

    var dataLayer: DataLayerManagerProtocol

    public init(dataLayer: DataLayerManagerProtocol) {
        self.dataLayer = dataLayer
    }

    /// `[String: Any]` containing all active persistent data.
    public var dictionary: [String: Any]? {
        dataLayer.allEventData
    }

    /// Add additional persistent data that will be available to all track calls
    ///     for lifetime of app. Values will overwrite any pre-existing values
    ///     for a given key.
    ///￼
    /// - Parameter data: `[String:Any]` of additional data to add.
    /// - Parameter expiration: `Expiration` level.
    public func add(data: [String: Any], expiration: Expiration = .forever) {
        dataLayer.add(data: data, expiration: expiration)
    }

    /// Add additional persistent data that will be available to all track calls
    ///     for lifetime of app. Values will overwrite any pre-existing values
    ///     for a given key.
    ///￼
    /// - Parameter value: `Any` should be `String` or `[String]`.
    /// - Parameter key: `String` name of key to be added.
    /// - Parameter expiration: `Expiration` level.
    public func add(value: Any,
                    for key: String,
                    expiration: Expiration = .forever) {
        dataLayer.add(key: key, value: value, expiration: expiration)
    }

    /// Delete a saved value for a given key.
    ///￼
    /// - Parameter forKeys: `[String]` Array of keys to remove.
    public func delete(for keys: [String]) {
        dataLayer.delete(for: keys)
    }

    /// Deletes persistent data for a specific key.
    /// - Parameter key: `String` to remove a specific value from the internal session data store.
    public func delete(for key: String) {
        dataLayer.delete(for: key)
    }

    /// Deletes all custom persisted data for current library instance.
    public func deleteAll() {
        dataLayer.deleteAll()
    }

}
