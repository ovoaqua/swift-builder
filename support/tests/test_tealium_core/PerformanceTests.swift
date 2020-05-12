//
//  PerformanceTests.swift
//  TealiumCore
//
//  Created by Christina S on 5/11/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

@testable import TealiumCollect
@testable import TealiumConsentManager
@testable import TealiumCore
@testable import TealiumLifecycle
@testable import TealiumVisitorService
import XCTest
#if os(iOS)
    @testable import TealiumAttribution
    @testable import TealiumAutotracking
//@testable import TealiumCrash
// @testable import TealiumLocation
// @testable import TealiumRemoteCommands
    @testable import TealiumTagManagement
#endif

class PerformanceTests: XCTestCase {

    var tealium: Tealium!
    var config: TealiumConfig!
    var expect: XCTestExpectation!
    var trackExpectation: XCTestExpectation!
    var iterations: Int!

    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }

    func testTimeToInitializeSimpleTealiumConfig() {
        iterations = 1000

        // Time: 0.002 sec
        self.measure {
            for _ in 0..<iterations {
                config = TealiumConfig(account: "testAccount", profile: "testProfile", environment: "testEnvironment")
            }
        }
    }

    func testTimeToInitializeTealiumConfigWithOptionalData() {
        iterations = 1000

        // Time: 0.003 sec
        self.measure {
            for _ in 0..<iterations {
                config = TealiumConfig(account: "testAccount", profile: "testProfile", environment: "testEnvironment", datasource: "testDatasource", optionalData: [TealiumCollectKey.overrideCollectUrl: "https://6372509c65ca83cb33983be9c6f8f204.m.pipedream.net",
                    TealiumVisitorServiceConstants.visitorServiceDelegate: self])
            }
        }
    }

    func testModulesManagerInitPerformance() {
        iterations = 100
        let eventDataManager = EventDataManager(config: defaultTealiumConfig)
        
        // Time: 0.285 sec
        self.measure {
            for _ in 0..<iterations {
                _ = ModulesManager(defaultTealiumConfig, eventDataManager: eventDataManager)
            }
        }
    }

    func testTimeToInitializeTealiumWithBaseModules() {
        iterations = 30
        let optionalCollectors = [String]()
        let knownDispatchers = ["TealiumCollect.TealiumCollectModule"]
        let modulesManager = ModulesManager(defaultTealiumConfig, eventDataManager: nil, optionalCollectors: optionalCollectors, knownDispatchers: knownDispatchers)
        defaultTealiumConfig.shouldUseRemotePublishSettings = false

        // Time: 0.137 sec
        self.measure {
            for iter in 0..<iterations {
                expect = expectation(description: "testTimeToInitializeTealiumWithAllModules\(iter)")
                tealium = Tealium(config: defaultTealiumConfig, modulesManager: modulesManager) { _ in
                    self.expect.fulfill()
                }
                wait(for: [expect], timeout: 10.0)
            }
        }
    }

    func testTimeToInitializeTealiumWithAllModules() {
        iterations = 10
        defaultTealiumConfig.shouldUseRemotePublishSettings = false

        // Time: 0.054 sec
        self.measure {
            for iter in 0..<iterations {
                expect = expectation(description: "testTimeToInitializeTealiumWithBaseModules\(iter)")
                tealium = Tealium(config: defaultTealiumConfig) { _ in
                    self.expect.fulfill()
                }
                wait(for: [expect], timeout: 2.0)
            }
        }
    }

    // TODO:
    func testTimeToDispatchTrackInCollect() {
        trackExpectation = expectation(description: "testTimeToDispatchTrackInCollect")
        let optionalCollectors = [String]()
        let knownDispatchers = ["TealiumCollect.TealiumCollectModule"]
        let modulesManager = ModulesManager(defaultTealiumConfig, eventDataManager: nil, optionalCollectors: optionalCollectors, knownDispatchers: knownDispatchers)
        defaultTealiumConfig.shouldUseRemotePublishSettings = false

        // Time: .0000402 sec
        self.measure {
            tealium = Tealium(config: defaultTealiumConfig, modulesManager: modulesManager) { _ in
                self.tealium.track(title: "tester", data: nil) { _, _, _ in

                }
            }
        }
        wait(for: [trackExpectation], timeout: 10.0)
    }

}

extension PerformanceTests: TealiumVisitorServiceDelegate {
    func didUpdate(visitorProfile: TealiumVisitorProfile) {
        if let json = try? JSONEncoder().encode(visitorProfile), let string = String(data: json, encoding: .utf8) {
            print(string)
        }
    }
}

extension PerformanceTests: TealiumModuleDelegate {
    func requestTrack(_ track: TealiumTrackRequest) {
        self.trackExpectation.fulfill()
    }
    func requestReleaseQueue(reason: String) {

    }
}
