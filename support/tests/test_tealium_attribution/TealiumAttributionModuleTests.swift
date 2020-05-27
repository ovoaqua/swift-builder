//
//  TealiumAttributionModuleTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 11/16/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

//  Application Test do to UIKit not being available to Unit Test Bundle

@testable import TealiumAttribution
@testable import TealiumCore
import XCTest

class TealiumAttributionModuleTests: XCTestCase {

    var module: TealiumAttributionModule?
    var config: TealiumConfig!
    var expectation: XCTestExpectation?
    var payload: [String: Any]?
    var attributionData = MockAttributionData()

    override func setUp() {
        config = TestTealiumHelper().getConfig()
        module = TealiumAttributionModule(config: config, delegate: nil, diskStorage: AttributionMockDiskStorage(), attributionData: attributionData)
    }

    func testGetAttributionData() {
        let allAttrData = self.module?.data
        XCTAssertNotNil(allAttrData?[TealiumAttributionKey.clickedDate])
        XCTAssertNotNil(allAttrData?[TealiumAttributionKey.idfa])
        XCTAssertNotNil(allAttrData?[TealiumAttributionKey.idfv])
        XCTAssertNotNil(allAttrData?[TealiumAttributionKey.orgName])
        XCTAssertNotNil(allAttrData?[TealiumAttributionKey.campaignName])
        XCTAssertNotNil(allAttrData?[TealiumAttributionKey.creativeSetName])

    }

}
