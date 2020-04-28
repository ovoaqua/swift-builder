//
//  SessionStarterTests.swift
//  TealiumCoreTests
//
//  Created by Christina S on 4/28/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
import XCTest

class SessionStarterTests: XCTestCase {

    var sessionStarter: SessionStarterProtocol!
    var config: TealiumConfig!
    override func setUp() {
        config = TealiumConfig(account: "ssTestAccount", profile: "ssTestProfile", environment: "ssTestEnv")
        sessionStarter = SessionStarter(config: config, urlSession: MockURLSessionSessionStarter())
    }

    override func tearDown() { }

    func testSessionURL() {
        let sessionURL = sessionStarter.sessionURL

        XCTAssertEqual(true, sessionURL.hasPrefix("https://tags.tiqcdn.com/utag/tiqapp/utag.v.js?a=ssTestAccount/ssTestProfile/"))
    }

//    func testRequestSessionSuccessful() {
//        sessionStarter.sessionRequest { response, error in
//            XCTAssertEqual(nil, error)
//            guard let statusCode = response?.statusCode else {
//                XCTFail("Did not receive successful response")
//                return
//            }
//            XCTAssertEqual(200, statusCode)
//        }
//    }
//
//    func testRequestSessionErrorInResponse() {
//        sessionStarter = TealiumSessionStarter(config: config, urlSession: MockURLSessionSessionManagerRequestError())
//        sessionStarter.sessionRequest { response, error in
//            XCTAssertEqual("Error when requesting a new session: ", error)
//            XCTAssertEqual(nil, response)
//        }
//    }
//
//    func testRequestSessionInvalidResponse() {
//        sessionStarter = TealiumSessionStarter(config: config, urlSession: MockURLSessionSessionManagerInvalidResponse())
//        sessionStarter.sessionRequest { response, error in
//            XCTAssertEqual("Invalid response when requesting a new session.", error)
//            XCTAssertEqual(nil, response)
//        }
//    }

}
