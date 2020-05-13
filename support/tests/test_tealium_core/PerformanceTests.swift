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

    var standardMetrics: [XCTPerformanceMetric] = [.wallClockTime,
                                                   XCTPerformanceMetric(rawValue: "com.apple.XCTPerformanceMetric_UserTime"),
                                                   XCTPerformanceMetric(rawValue: "com.apple.XCTPerformanceMetric_RunTime"),
                                                   XCTPerformanceMetric(rawValue: "com.apple.XCTPerformanceMetric_SystemTime")]

    var allMetrics: [XCTPerformanceMetric] = [.wallClockTime,
                                              XCTPerformanceMetric(rawValue: "com.apple.XCTPerformanceMetric_UserTime"),
                                              XCTPerformanceMetric(rawValue: "com.apple.XCTPerformanceMetric_RunTime"),
                                              XCTPerformanceMetric(rawValue: "com.apple.XCTPerformanceMetric_SystemTime"),
                                              XCTPerformanceMetric(rawValue: "com.apple.XCTPerformanceMetric_TransientVMAllocationsKilobytes"),
                                              XCTPerformanceMetric(rawValue: "com.apple.XCTPerformanceMetric_TemporaryHeapAllocationsKilobytes"),
                                              XCTPerformanceMetric(rawValue: "com.apple.XCTPerformanceMetric_HighWaterMarkForVMAllocations"),
                                              XCTPerformanceMetric(rawValue: "com.apple.XCTPerformanceMetric_TotalHeapAllocationsKilobytes"),
                                              XCTPerformanceMetric(rawValue: "com.apple.XCTPerformanceMetric_PersistentVMAllocations"),
                                              XCTPerformanceMetric(rawValue: "com.apple.XCTPerformanceMetric_TransientHeapAllocationsKilobytes"),
                                              XCTPerformanceMetric(rawValue: "com.apple.XCTPerformanceMetric_PersistentHeapAllocationsNodes"),
                                              XCTPerformanceMetric(rawValue: "com.apple.XCTPerformanceMetric_HighWaterMarkForHeapAllocations"),
                                              XCTPerformanceMetric(rawValue: "com.apple.XCTPerformanceMetric_TransientHeapAllocationsNodes")]

    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }

    func testTimeToInitializeSimpleTealiumConfig() {

        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            config = TealiumConfig(account: "testAccount", profile: "testProfile", environment: "testEnvironment")
            self.stopMeasuring()
        }
    }

    func testTimeToInitializeTealiumConfigWithOptionalData() {

        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            config = TealiumConfig(account: "testAccount", profile: "testProfile", environment: "testEnvironment", datasource: "testDatasource", optionalData: [TealiumCollectKey.overrideCollectUrl: "https://6372509c65ca83cb33983be9c6f8f204.m.pipedream.net",
                                                                                                                                                                TealiumVisitorServiceConstants.visitorServiceDelegate: self])
            self.stopMeasuring()
        }
    }

    func testModulesManagerInitPerformance() {
        let eventDataManager = EventDataManager(config: defaultTealiumConfig)

        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = ModulesManager(defaultTealiumConfig, eventDataManager: eventDataManager)
            self.stopMeasuring()
        }
    }

    func testTimeToInitializeTealiumWithBaseModules() {
        let optionalCollectors = [String]()
        let knownDispatchers = ["TealiumCollect.TealiumCollectModule"]
        let modulesManager = ModulesManager(defaultTealiumConfig, eventDataManager: nil, optionalCollectors: optionalCollectors, knownDispatchers: knownDispatchers)
        defaultTealiumConfig.shouldUseRemotePublishSettings = false

        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            tealium = Tealium(config: defaultTealiumConfig, modulesManager: modulesManager, enableCompletion: nil)
            self.stopMeasuring()
        }
    }

    func testTimeToInitializeTealiumWithAllModules() {
        defaultTealiumConfig.shouldUseRemotePublishSettings = false

        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            tealium = Tealium(config: defaultTealiumConfig, modulesManager: nil, enableCompletion: nil)
            self.stopMeasuring()
        }
    }

    func testTimeToDispatchTrackInCollect() {
        let optionalCollectors = [String]()
        let knownDispatchers = ["TealiumCollect.TealiumCollectModule"]
        let modulesManager = ModulesManager(defaultTealiumConfig, eventDataManager: nil, optionalCollectors: optionalCollectors, knownDispatchers: knownDispatchers)
        defaultTealiumConfig.shouldUseRemotePublishSettings = false
        defaultTealiumConfig.batchingEnabled = false
        tealium = Tealium(config: defaultTealiumConfig, modulesManager: modulesManager, enableCompletion: nil)
        tealium.consentManager?.setUserConsentStatus(.consented)

        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            tealium.track(title: "tester")
            self.stopMeasuring()
        }

    }

    func testTimeToDispatchTrackInTagManagement() {
        //trackExpectation = expectation(description: "testTimeToDispatchTrackInTagManagement")

        let optionalCollectors = [String]()
        let knownDispatchers = ["TealiumTagManagement.TealiumTagManagementModule"]
        let modulesManager = ModulesManager(defaultTealiumConfig, eventDataManager: nil, optionalCollectors: optionalCollectors, knownDispatchers: knownDispatchers)
        defaultTealiumConfig.shouldUseRemotePublishSettings = false
        defaultTealiumConfig.batchingEnabled = false
        tealium = Tealium(config: defaultTealiumConfig, modulesManager: modulesManager, enableCompletion: nil)
        tealium.consentManager?.setUserConsentStatus(.consented)

        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            tealium.track(title: "tester")
            self.stopMeasuring()
        }

    }

    // MARK: Individual Module Performance Tests
    func testAppDataModuleInit() {
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = TealiumAppDataModule(config: defaultTealiumConfig, delegate: self, diskStorage: nil, completion: { _ in })
            self.stopMeasuring()
        }
    }

    func testAppDataCollection() {
        let module = TealiumAppDataModule(config: defaultTealiumConfig, delegate: self, diskStorage: nil, completion: { _ in })
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = module.data
            self.stopMeasuring()
        }
    }

    func testAttributionModuleInit() {
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = TealiumAttributionModule(config: defaultTealiumConfig, delegate: self, diskStorage: nil, completion: { _ in })
            self.stopMeasuring()
        }
    }

    func testAttributionDataCollection() {
        let module = TealiumAttributionModule(config: defaultTealiumConfig, delegate: self, diskStorage: nil, completion: { _ in })
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = module.data
            self.stopMeasuring()
        }
    }

    func testAutotrackingModuleInit() {
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = TealiumAutotrackingModule(config: defaultTealiumConfig, delegate: self, diskStorage: nil, completion: { _ in })
            self.stopMeasuring()
        }
    }

    func testAutotrackingDataCollection() {
        let module = TealiumAutotrackingModule(config: defaultTealiumConfig, delegate: self, diskStorage: nil, completion: { _ in })
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = module.data
            self.stopMeasuring()
        }
    }

    func testCollectModuleInit() {
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = TealiumCollectModule(config: defaultTealiumConfig, delegate: self, completion: { _ in })
            self.stopMeasuring()
        }
    }

    func testConnectivityModuleInit() {
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = TealiumConnectivity(config: defaultTealiumConfig)
            self.stopMeasuring()
        }
    }

    func testConnectivityHasViableConnection() {
        let module = TealiumConnectivity(config: defaultTealiumConfig)
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = module.hasViableConnection
            self.stopMeasuring()
        }
    }

    func testConsentManagerModuleInit() {
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = TealiumConsentManagerModule(config: defaultTealiumConfig, delegate: self, diskStorage: nil, completion: { _ in })
            self.stopMeasuring()
        }
    }

    func testConsentManagerDataCollection() {
        let module = TealiumConsentManagerModule(config: defaultTealiumConfig, delegate: self, diskStorage: nil, completion: { _ in })
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = module.data
            self.stopMeasuring()
        }
    }

    func testCrashModuleInit() {
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = TealiumCrashModule(config: defaultTealiumConfig, delegate: self, diskStorage: nil, completion: { _ in })
            self.stopMeasuring()
        }
    }

    func testCrashDataCollection() {
        let module = TealiumCrashModule(config: defaultTealiumConfig, delegate: self, diskStorage: nil, completion: { _ in })
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = module.data
            self.stopMeasuring()
        }
    }

    func testDeviceDataModuleInit() {
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = DeviceDataModule(config: defaultTealiumConfig, delegate: self, diskStorage: nil, completion: { _ in })
            self.stopMeasuring()
        }
    }

    func testDeviceDataCollection() {
        let module = DeviceDataModule(config: defaultTealiumConfig, delegate: self, diskStorage: nil, completion: { _ in })
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = module.data
            self.stopMeasuring()
        }
    }

    func testDispatchManagerInit() {
        let collect = TealiumCollectModule(config: defaultTealiumConfig, delegate: self, completion: { _ in })
        let dispatchers = [collect]
        let connecivity = TealiumConnectivity(config: defaultTealiumConfig)
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = DispatchManager(dispatchers: dispatchers, dispatchValidators: nil, dispatchListeners: nil, delegate: nil, connectivityManager: connecivity, logger: nil, config: defaultTealiumConfig)
            self.stopMeasuring()
        }
    }

    func testEventDataManagerInit() {
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = EventDataManager(config: defaultTealiumConfig)
            self.stopMeasuring()
        }
    }

    func testEventDataCollectionWithStandardData() {
        let eventData = EventDataManager(config: defaultTealiumConfig)
        eventData.deleteAll()
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = eventData.allEventData
            self.stopMeasuring()
        }
    }

    func testEventDataCollectionWithLargePersistentDataSet() {
        let eventDataManager = EventDataManager(config: defaultTealiumConfig)
        eventDataManager.deleteAll()
        let json = loadStub(from: "large-event-data", with: "json")
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-YYYY HH:MM:ss"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        guard let decoded = try? decoder.decode([EventDataItem].self, from: json) else {
            return
        }
        decoded.forEach {
            eventDataManager.add(key: $0.key, value: $0.value, expiration: .forever)
        }
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = eventDataManager.allEventData
            self.stopMeasuring()
        }
    }

    func testLifecycleModuleInit() {
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = TealiumLifecycleModule(config: defaultTealiumConfig, delegate: self, diskStorage: nil, completion: { _ in })
            self.stopMeasuring()
        }
    }

    func testLifecycleDataCollection() {
        let module = TealiumLifecycleModule(config: defaultTealiumConfig, delegate: self, diskStorage: nil, completion: { _ in })
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = module.data
            self.stopMeasuring()
        }
    }

    func testLocationModuleInit() {
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = TealiumLocationModule(config: defaultTealiumConfig, delegate: self, diskStorage: nil, completion: { _ in })
            self.stopMeasuring()
        }
    }

    func testLocationDataCollection() {
        let module = TealiumLocationModule(config: defaultTealiumConfig, delegate: self, diskStorage: nil, completion: { _ in })
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = module.data
            self.stopMeasuring()
        }
    }

    func testLoggerModuleInit() {
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = TealiumLogger(config: defaultTealiumConfig)
            self.stopMeasuring()
        }
    }

    func testLoggerWithOSLog() {
        defaultTealiumConfig.loggerType = .os
        let logger = TealiumLogger(config: defaultTealiumConfig)
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            let logRequest = TealiumLogRequest(title: "Hello There", message: "This is a test message", info: ["info1": "one", "info2": 123], logLevel: .info, category: .general)
            logger.log(logRequest)
            self.stopMeasuring()
        }
    }

    func testLoggerWithPrintLog() {
        defaultTealiumConfig.loggerType = .print
        let logger = TealiumLogger(config: defaultTealiumConfig)
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            let logRequest = TealiumLogRequest(title: "Hello There", message: "This is a test message", info: ["info1": "one", "info2": 123], logLevel: .info, category: .general)
            logger.log(logRequest)
            self.stopMeasuring()
        }
    }

    // TODO: Remote Command Module

    func testTagManagementModuleInit() {
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = TealiumTagManagementModule(config: defaultTealiumConfig, delegate: self, completion: { _ in })
            self.stopMeasuring()
        }
    }

    func testVisitorServiceModuleInit() {
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = TealiumVisitorServiceModule(config: defaultTealiumConfig, delegate: self, diskStorage: nil, completion: { _ in })
            self.stopMeasuring()
        }
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
