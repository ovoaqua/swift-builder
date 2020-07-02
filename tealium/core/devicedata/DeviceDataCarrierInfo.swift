//
//  DeviceDataCarrierInfo.swift
//  tealium-swift
//
//  Created by Craig Rouse on 20/08/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

#if os(tvOS)
#elseif os(watchOS)
#else
import CoreTelephony
#endif
import Foundation

extension DeviceData {
    /// - Returns: `[String: String]` containing current network carrier info
    class var carrierInfo: [String: String] {
        // only available on iOS
        var carrierInfo: [String: String]
        // avoiding direct assignment to suppress spurious compiler warning (never mutated)
        carrierInfo = [String: String]()
        #if os(iOS)
        // beginning in iOS 12, Xcode generates lots of errors
        // when calling CTTelephonyNetworkInfo from the simulator
        // this is a workaround
        #if targetEnvironment(simulator)
        carrierInfo = [
            DeviceDataKey.carrierMNC: "00",
            DeviceDataKey.carrierMCC: "000",
            DeviceDataKey.carrierISO: "us",
            DeviceDataKey.carrier: "simulator",
            DeviceDataKey.carrierMNCLegacy: "00",
            DeviceDataKey.carrierMCCLegacy: "000",
            DeviceDataKey.carrierISOLegacy: "us",
            DeviceDataKey.carrierLegacy: "simulator"
        ]
        #elseif targetEnvironment(macCatalyst)
        carrierInfo = [
            DeviceDataKey.carrierMNC: "00",
            DeviceDataKey.carrierMCC: "000",
            DeviceDataKey.carrierISO: "us",
            DeviceDataKey.carrier: "macCatalyst",
            DeviceDataKey.carrierMNCLegacy: "00",
            DeviceDataKey.carrierMCCLegacy: "000",
            DeviceDataKey.carrierISOLegacy: "us",
            DeviceDataKey.carrierLegacy: "macCatalyst"
        ]
        #else
        let networkInfo = CTTelephonyNetworkInfo()
        var carrier: CTCarrier?
        if #available(iOS 12.1, *) {
            if let newCarrier = networkInfo.serviceSubscriberCellularProviders {
                // pick up the first carrier in the list
                for currentCarrier in newCarrier {
                    carrier = currentCarrier.value
                    break
                }
            }
        } else {
            carrier = networkInfo.subscriberCellularProvider
        }
        carrierInfo = [
            DeviceDataKey.carrierMNCLegacy: carrier?.mobileNetworkCode ?? "",
            DeviceDataKey.carrierMNC: carrier?.mobileNetworkCode ?? "",
            DeviceDataKey.carrierMCCLegacy: carrier?.mobileCountryCode ?? "",
            DeviceDataKey.carrierMCC: carrier?.mobileCountryCode ?? "",
            DeviceDataKey.carrierISOLegacy: carrier?.isoCountryCode ?? "",
            DeviceDataKey.carrierISO: carrier?.isoCountryCode ?? "",
            DeviceDataKey.carrierLegacy: carrier?.carrierName ?? "",
            DeviceDataKey.carrier: carrier?.carrierName ?? ""
        ]
        #endif
        #endif
        return carrierInfo
    }
}
