//
//  DeviceDataModule.swift
//  tealium-swift
//
//  Created by Jason Koo on 8/3/17.
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

#if os(OSX)
#else
import UIKit
#endif
import Foundation
#if os(tvOS)
#elseif os (watchOS)
#else
import CoreTelephony
#endif
#if os(watchOS)
import WatchKit
#endif

public class DeviceDataModule: Collector {
    public let id: String = ModuleNames.devicedata

    public var data: [String: Any]? {
        guard config.shouldCollectTealiumData else {
            return nil
        }
        cachedData += trackTimeData
        return cachedData
    }

    var isMemoryReportingEnabled: Bool {
        config.memoryReportingEnabled
    }
    var deviceDataCollection: DeviceDataCollection
    var cachedData = [String: Any]()
    public var config: TealiumConfig

    /// Initializes the module
    ///
    /// - Parameter config: `TealiumConfig` instance
    /// - Parameter delegate: `TealiumModuleDelegate` instance
    /// - Parameter diskStorage: `TealiumDiskStorageProtocol` instance
    /// - Parameter completion: `ModuleCompletion` block to be called when init is finished
    required public init(config: TealiumConfig,
                         delegate: TealiumModuleDelegate?,
                         diskStorage: TealiumDiskStorageProtocol?,
                         completion: ModuleCompletion) {
        self.config = config
        deviceDataCollection = DeviceData()
        cachedData = enableTimeData
        completion((.success(true), nil))
    }

    /// Data that only needs to be retrieved once for the lifetime of the host app.
    ///
    /// - Returns: `[String:Any]` of enable-time device data.
    var enableTimeData: [String: Any] {
        var result = [String: Any]()

        result[TealiumKey.architectureLegacy] = deviceDataCollection.architecture()
        result[TealiumKey.architecture] = result[TealiumKey.architectureLegacy] ?? ""
        result[DeviceDataKey.osBuildLegacy] = DeviceData.oSBuild
        result[DeviceDataKey.osBuild] = DeviceData.oSBuild
        result[TealiumKey.cpuTypeLegacy] = deviceDataCollection.cpuType
        result[TealiumKey.cpuType] = result[TealiumKey.cpuTypeLegacy] ?? ""
        result += deviceDataCollection.model
        result[DeviceDataKey.osVersionLegacy] = DeviceData.oSVersion
        result[DeviceDataKey.osVersion] = result[DeviceDataKey.osVersionLegacy] ?? ""
        result[TealiumKey.osName] = DeviceData.oSName
        result[TealiumKey.platform] = result[TealiumKey.osName] ?? ""
        result[TealiumKey.resolution] = DeviceData.resolution
        return result
    }

    /// Data that needs to be polled at time of interest, these may change during the lifetime of the host app.
    ///
    /// - Returns: `[String: Any]` of track-time device data.
    var trackTimeData: [String: Any] {
        var result = [String: Any]()

        result[DeviceDataKey.batteryPercentLegacy] = DeviceData.batteryPercent
        result[DeviceDataKey.batteryPercent] = result[DeviceDataKey.batteryPercentLegacy] ?? ""
        result[DeviceDataKey.isChargingLegacy] = DeviceData.isCharging
        result[DeviceDataKey.isCharging] = result[DeviceDataKey.isChargingLegacy] ?? ""
        result[TealiumKey.languageLegacy] = DeviceData.iso639Language
        result[TealiumKey.language] = result[TealiumKey.languageLegacy] ?? ""
        if isMemoryReportingEnabled {
            result += deviceDataCollection.memoryUsage
        }
        result += deviceDataCollection.orientation
        result += DeviceData.carrierInfo
        return result
    }
}
