//
//  MockAttributionData.swift
//  TealiumAttributionTests-iOS
//
//  Created by Christina S on 5/21/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumAttribution

class MockAttributionData: TealiumAttributionDataProtocol {
    var appleAttributionDetails: PersistentAttributionData?
    var appleSearchAdsDataCalled = 0
    init() {
        self.appleAttributionDetails = PersistentAttributionData(withDictionary: [
            TealiumAttributionKey.clickedWithin30D: "true",
            TealiumAttributionKey.orgName: "org name",
            TealiumAttributionKey.orgId: "555555",
            TealiumAttributionKey.campaignId: "12345678",
            TealiumAttributionKey.campaignName: "campaign name",
            TealiumAttributionKey.conversionDate: "2020-01-04T17:18:07Z",
            TealiumAttributionKey.conversionType: "Download",
            TealiumAttributionKey.clickedDate: "2020-01-04T17:17:00Z",
            TealiumAttributionKey.adGroupId: "12345678",
            TealiumAttributionKey.adGroupName: "adgroup name",
            TealiumAttributionKey.region: "US",
            TealiumAttributionKey.adKeyword: "keyword",
            TealiumAttributionKey.adKeywordMatchType: "Broad",
            TealiumAttributionKey.creativeSetId: "12345678",
            TealiumAttributionKey.creativeSetName: "Creative Set name"
        ])
    }

    var allAttributionData: [String: Any] {
        guard var allData = appleAttributionDetails!.toDictionary() as? [String: Any] else {
            return [:]
        }
        allData += volatileData
        return allData
    }

    var idfa: String {
        "IDFA8250-458d-40ed-b150-e0bffeeee849"
    }

    var idfv: String {
        "IDFV72a0-aef8-47be-9cf5-2628b031d4d9"
    }

    var volatileData: [String: Any] {
        [TealiumAttributionKey.idfa: idfa,
         TealiumAttributionKey.idfv: idfv,
         TealiumAttributionKey.isTrackingAllowed: isAdvertisingTrackingEnabled]
    }

    var isAdvertisingTrackingEnabled: String = "true"

    func appleSearchAdsData(_ completion: @escaping (PersistentAttributionData) -> Void) {
        appleSearchAdsDataCalled += 1
        completion(appleAttributionDetails!)
    }

}
public extension Dictionary where Key == String, Value == Any {
    static func += <K, V>(left: inout [K: V], right: [K: V]) {
        for (key, value) in right {
            left.updateValue(value, forKey: key)
        }
    }
}
