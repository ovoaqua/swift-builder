//
//  TealiumModulesManagerTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 10/11/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

//@testable import TealiumAppData
//@testable import TealiumCollect
//@testable import TealiumConsentManager
@testable import TealiumCore
//@testable import TealiumDelegate
//@testable import TealiumDeviceData
//@testable import TealiumAttribution
//@testable import TealiumVisitorService
import XCTest

var defaultTealiumConfig: TealiumConfig { TealiumConfig(account: "tealiummobile",
                                                        profile: "demo",
                                                        environment: "dev",
                                                        optionalData: nil)
}

class TealiumModulesManagerTests: XCTestCase {

    var modulesManager: ModulesManager?

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        modulesManager = nil
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

}
