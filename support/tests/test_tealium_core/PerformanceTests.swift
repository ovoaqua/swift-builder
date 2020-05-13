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
@testable import TealiumCrash
@testable import TealiumLocation
// @testable import TealiumRemoteCommands
@testable import TealiumTagManagement
#endif

class PerformanceTests: XCTestCase {

    var tealium: Tealium!
    var config: TealiumConfig!
    var expect: XCTestExpectation!
    var trackExpectation: XCTestExpectation!
    var visitorExpectation: XCTestExpectation!
    var iterations: Int!
    var start: Date!

    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }

    func testTimeToInitializeSimpleTealiumConfig() {

        self.measure {
            config = TealiumConfig(account: "testAccount", profile: "testProfile", environment: "testEnvironment")
        }
    }

    func testTimeToInitializeTealiumConfigWithOptionalData() {

        self.measure {
            config = TealiumConfig(account: "testAccount", profile: "testProfile", environment: "testEnvironment", datasource: "testDatasource", optionalData: [TealiumCollectKey.overrideCollectUrl: "https://6372509c65ca83cb33983be9c6f8f204.m.pipedream.net",
                                                                                                                                                                TealiumVisitorServiceConstants.visitorServiceDelegate: self])
        }
    }

    func testModulesManagerInitPerformance() {
        iterations = 100
        let eventDataManager = EventDataManager(config: defaultTealiumConfig)

        self.measure {
            _ = ModulesManager(defaultTealiumConfig, eventDataManager: eventDataManager)
        }
    }

    func testTimeToInitializeTealiumWithBaseModules() {
        let optionalCollectors = [String]()
        let knownDispatchers = ["TealiumCollect.TealiumCollectModule"]
        let modulesManager = ModulesManager(defaultTealiumConfig, eventDataManager: nil, optionalCollectors: optionalCollectors, knownDispatchers: knownDispatchers)
        defaultTealiumConfig.shouldUseRemotePublishSettings = false

        self.measure {
            tealium = Tealium(config: defaultTealiumConfig, modulesManager: modulesManager, enableCompletion: nil)
        }
    }

    func testTimeToInitializeTealiumWithAllModules() {
        defaultTealiumConfig.shouldUseRemotePublishSettings = false

        self.measure {
            tealium = Tealium(config: defaultTealiumConfig, modulesManager: nil, enableCompletion: nil)
        }
    }

    func testTimeToDispatchTrackInCollect() {
        trackExpectation = expectation(description: "testTimeToDispatchTrackInCollect")

        let optionalCollectors = [String]()
        let knownDispatchers = ["TealiumCollect.TealiumCollectModule"]
        let modulesManager = ModulesManager(defaultTealiumConfig, eventDataManager: nil, optionalCollectors: optionalCollectors, knownDispatchers: knownDispatchers)
        defaultTealiumConfig.shouldUseRemotePublishSettings = false
        defaultTealiumConfig.batchingEnabled = false
        tealium = Tealium(config: defaultTealiumConfig, modulesManager: modulesManager, enableCompletion: nil)
        tealium.consentManager?.setUserConsentStatus(.consented)
        start = Date()

        tealium.track(title: "tester", data: nil) { _, _, _ in
            let diff = Date().timeIntervalSince(self.start)
            print("testTimeToDispatchTrackInCollect: \(String(diff))")
            self.trackExpectation.fulfill()
        }

        wait(for: [trackExpectation], timeout: 10.0)
    }

    func testTimeToDispatchTrackInTagManagement() {
        trackExpectation = expectation(description: "testTimeToDispatchTrackInTagManagement")

        let optionalCollectors = [String]()
        let knownDispatchers = ["TealiumTagManagement.TealiumTagManagementModule"]
        let modulesManager = ModulesManager(defaultTealiumConfig, eventDataManager: nil, optionalCollectors: optionalCollectors, knownDispatchers: knownDispatchers)
        defaultTealiumConfig.shouldUseRemotePublishSettings = false
        defaultTealiumConfig.batchingEnabled = false
        tealium = Tealium(config: defaultTealiumConfig, modulesManager: modulesManager, enableCompletion: nil)
        tealium.consentManager?.setUserConsentStatus(.consented)
        start = Date()

        tealium.track(title: "tester", data: nil) { _, _, _ in
            let diff = Date().timeIntervalSince(self.start)
            print("testTimeToDispatchTrackInTagManagement: \(String(diff))")
            self.trackExpectation.fulfill()
        }

        wait(for: [trackExpectation], timeout: 10.0)
    }

    // MARK: Individual Module Performance Tests
    func testAppDataModuleInit() {
        self.measure {
            _ = TealiumAppDataModule(config: defaultTealiumConfig, delegate: self, diskStorage: nil, completion: { _ in })
        }
    }

    func testAppDataCollection() {
        let module = TealiumAppDataModule(config: defaultTealiumConfig, delegate: self, diskStorage: nil, completion: { _ in })
        self.measure {
            _ = module.data
        }
    }

    func testAttributionModuleInit() {
        self.measure {
            _ = TealiumAttributionModule(config: defaultTealiumConfig, delegate: self, diskStorage: nil, completion: { _ in })
        }
    }

    func testAttributionDataCollection() {
        let module = TealiumAttributionModule(config: defaultTealiumConfig, delegate: self, diskStorage: nil, completion: { _ in })
        self.measure {
            _ = module.data
        }
    }

    func testAutotrackingModuleInit() {
        self.measure {
            _ = TealiumAutotrackingModule(config: defaultTealiumConfig, delegate: self, diskStorage: nil, completion: { _ in })
        }
    }

    func testAutotrackingDataCollection() {
        let module = TealiumAutotrackingModule(config: defaultTealiumConfig, delegate: self, diskStorage: nil, completion: { _ in })
        self.measure {
            _ = module.data
        }
    }

    func testCollectModuleInit() {
        self.measure {
            _ = TealiumCollectModule(config: defaultTealiumConfig, delegate: self, completion: { _ in })
        }
    }

    func testConnectivityModuleInit() {
        self.measure {
            _ = TealiumConnectivity(config: config)
        }
    }

    func testConnectivityHasViableConnection() {
        let module = TealiumConnectivity(config: config)
        self.measure {
            _ = module.hasViableConnection
        }
    }

    func testConsentManagerModuleInit() {
        self.measure {
            _ = TealiumConsentManagerModule(config: defaultTealiumConfig, delegate: self, diskStorage: nil, completion: { _ in })
        }
    }

    func testConsentManagerDataCollection() {
        let module = TealiumConsentManagerModule(config: defaultTealiumConfig, delegate: self, diskStorage: nil, completion: { _ in })
        self.measure {
            _ = module.data
        }
    }

    func testCrashModuleInit() {
        self.measure {
            _ = TealiumCrashModule(config: defaultTealiumConfig, delegate: self, diskStorage: nil, completion: { _ in })
        }
    }

    func testCrashDataCollection() {
        let module = TealiumCrashModule(config: defaultTealiumConfig, delegate: self, diskStorage: nil, completion: { _ in })
        self.measure {
            _ = module.data
        }
    }

    func testDeviceDataModuleInit() {
        self.measure {
            _ = DeviceDataModule(config: defaultTealiumConfig, delegate: self, diskStorage: nil, completion: { _ in })
        }
    }

    func testDeviceDataCollection() {
        let module = DeviceDataModule(config: defaultTealiumConfig, delegate: self, diskStorage: nil, completion: { _ in })
        self.measure {
            _ = module.data
        }
    }

    func testDispatchManagerInit() {
        let collect = TealiumCollectModule(config: defaultTealiumConfig, delegate: self, completion: { _ in })
        let dispatchers = [collect]
        let connecivity = TealiumConnectivity(config: defaultTealiumConfig)
        self.measure {
            _ = DispatchManager(dispatchers: dispatchers, dispatchValidators: nil, dispatchListeners: nil, delegate: nil, connectivityManager: connecivity, logger: nil, config: defaultTealiumConfig)
        }
    }

    func testEventDataManagerInit() {
        self.measure {
            _ = EventDataManager(config: defaultTealiumConfig)
        }
    }

    func testEventDataCollectionWithStandardData() {
        let eventData = EventDataManager(config: defaultTealiumConfig)
        self.measure {
            _ = eventData.allEventData
        }
    }

    func testEventDataCollectionWithLargePersistentDataSet() {
        let eventDataManager = EventDataManager(config: defaultTealiumConfig)
        let json = loadStub(from: "large-event-data", with: "json")
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-YYYY HH:MM:ss"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        guard let decoded = try? decoder.decode([EventDataItem].self, from: json) else {
            return
        }
        decoded.forEach {
            eventDataManager.add(key: $0.key, value: $0.value, expiration: .after($0.expires))
        }
        self.measure {
            _ = eventDataManager.allEventData
        }
    }

    func testLifecycleModuleInit() {
        self.measure {
            _ = TealiumLifecycleModule(config: defaultTealiumConfig, delegate: self, diskStorage: nil, completion: { _ in })
        }
    }

    func testLifecycleDataCollection() {
        let module = TealiumLifecycleModule(config: defaultTealiumConfig, delegate: self, diskStorage: nil, completion: { _ in })
        self.measure {
            _ = module.data
        }
    }

    func testLocationModuleInit() {
        self.measure {
            _ = TealiumLocationModule(config: defaultTealiumConfig, delegate: self, diskStorage: nil, completion: { _ in })
        }
    }

    func testLocationDataCollection() {
        let module = TealiumLocationModule(config: defaultTealiumConfig, delegate: self, diskStorage: nil, completion: { _ in })
        self.measure {
            _ = module.data
        }
    }

    func testLoggerModuleInit() {
        self.measure {
            _ = TealiumLogger(config: defaultTealiumConfig)
        }
    }

    func testLoggerWithOSLog() {
        defaultTealiumConfig.loggerType = .os
        let logger = TealiumLogger(config: defaultTealiumConfig)
        self.measure {
            let logRequest = TealiumLogRequest(title: "Hello There", message: "This is a test message", info: ["info1": "one", "info2": 123], logLevel: .info, category: .general)
            logger.log(logRequest)
        }
    }

    func testLoggerWithPrintLog() {
        defaultTealiumConfig.loggerType = .print
        let logger = TealiumLogger(config: defaultTealiumConfig)
        self.measure {
            let logRequest = TealiumLogRequest(title: "Hello There", message: "This is a test message", info: ["info1": "one", "info2": 123], logLevel: .info, category: .general)
            logger.log(logRequest)
        }
    }

    // TODO: Remote Command Module

    func testTagManagementModuleInit() {
        self.measure {
            _ = TealiumTagManagementModule(config: defaultTealiumConfig, delegate: self, completion: { _ in })
        }
    }

    func testVisitorServiceModuleInit() {
        self.measure {
            _ = TealiumVisitorServiceModule(config: defaultTealiumConfig, delegate: self, diskStorage: nil, completion: { _ in })
        }
    }

    func testVisitorServiceModuleDelegate() {
        visitorExpectation = expectation(description: "testVisitorServiceModuleDelegate")

        defaultTealiumConfig.shouldUseRemotePublishSettings = false
        defaultTealiumConfig.batchingEnabled = false
        defaultTealiumConfig.visitorServiceDelegate = self
        tealium = Tealium(config: defaultTealiumConfig, modulesManager: nil, enableCompletion: nil)
        tealium.consentManager?.setUserConsentStatus(.consented)
        start = Date()

        tealium.track(title: "tester")

        wait(for: [visitorExpectation], timeout: 10.0)
    }

}

extension PerformanceTests: TealiumVisitorServiceDelegate {
    func didUpdate(visitorProfile: TealiumVisitorProfile) {
        let diff = Date().timeIntervalSince(start)
        print("testVisitorServiceModuleDelegate: \(String(diff))")
        self.visitorExpectation.fulfill()
    }
}

extension PerformanceTests: TealiumModuleDelegate {
    func requestTrack(_ track: TealiumTrackRequest) {

    }

    func requestReleaseQueue(reason: String) {

    }
}

extension XCTestCase {

    fileprivate func loadStub(from file: String, with extension: String) -> Data {
        let bundle = Bundle(for: classForCoder)
        let url = bundle.url(forResource: file, withExtension: `extension`)
        return try! Data(contentsOf: url!)
    }

}
