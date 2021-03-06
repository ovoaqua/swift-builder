//
//  TealiumModulesManagerTests.swift
//  tealium-swift
//
//  Created by Craig Rouse on 04/30/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

@testable import TealiumCollect
@testable import TealiumCore
#if os(iOS)
@testable import TealiumTagManagement
#endif
import XCTest

var defaultTealiumConfig: TealiumConfig { TealiumConfig(account: "tealiummobile",
                                                        profile: "demo",
                                                        environment: "dev",
                                                        options: nil)
}

class TealiumModulesManagerTests: XCTestCase {

    var modulesManager: ModulesManager {
        let config = testTealiumConfig
        config.shouldUseRemotePublishSettings = false
        #if os(iOS)
        config.dispatchers = [Dispatchers.TagManagement, Dispatchers.Collect]
        #else
        config.dispatchers = [Dispatchers.Collect]
        #endif
        config.logLevel = TealiumLogLevel.error
        config.loggerType = .print
        let modulesManager = ModulesManager(config, dataLayer: nil)
        modulesManager.connectionRestored()
        return modulesManager
    }

    func modulesManagerForConfig(config: TealiumConfig) -> ModulesManager {
        return ModulesManager(config, dataLayer: nil)
    }

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        TealiumExpectations.expectations = [:]
    }

    func testUpdateConfig() {
        let modulesManager = self.modulesManager

        #if os(iOS)
        XCTAssertTrue(testTealiumConfig.isTagManagementEnabled)
        #endif

        let config = testTealiumConfig
        config.shouldUseRemotePublishSettings = false
        config.isCollectEnabled = false
        config.isTagManagementEnabled = true
        modulesManager.updateConfig(config: config)
        XCTAssertFalse(modulesManager.dispatchers.contains(where: { $0.id == "Collect" }))
        #if os(iOS)
        XCTAssertTrue(modulesManager.dispatchers.contains(where: { $0.id == "TagManagement" }))
        #endif
        config.isTagManagementEnabled = false
        modulesManager.updateConfig(config: config)
        XCTAssertFalse(modulesManager.dispatchers.contains(where: { $0.id == "TagManagement" }))
        config.isTagManagementEnabled = true
        config.isCollectEnabled = true
        modulesManager.updateConfig(config: config)
        #if os(iOS)
        XCTAssertTrue(modulesManager.dispatchers.contains(where: { $0.id == "TagManagement" }))
        #endif
        XCTAssertTrue(modulesManager.dispatchers.contains(where: { $0.id == "Collect" }))
    }

    func testAddCollector() {
        let collector = DummyCollector(config: testTealiumConfig, delegate: self, diskStorage: nil) { _ in

        }
        let modulesManager = ModulesManager(testTealiumConfig, dataLayer: DummyDataManagerNoData(), optionalCollectors: nil, knownDispatchers: nil)

        modulesManager.collectors = []
        modulesManager.dispatchListeners = []
        modulesManager.dispatchValidators = []

        modulesManager.addCollector(collector)
        XCTAssertTrue(modulesManager.collectors.contains(where: { $0.id == "Dummy" }))

        XCTAssertTrue(modulesManager.dispatchListeners.contains(where: { ($0 as! Collector).id == "Dummy" }))
        XCTAssertTrue(modulesManager.dispatchValidators.contains(where: { ($0 as! Collector).id == "Dummy" }))

        XCTAssertEqual(modulesManager.collectors.count, 1)
        XCTAssertEqual(modulesManager.dispatchListeners.count, 1)

        modulesManager.addCollector(collector)
        modulesManager.addCollector(collector)

        XCTAssertEqual(modulesManager.collectors.count, 1)
        XCTAssertEqual(modulesManager.dispatchListeners.count, 1)
        XCTAssertEqual(modulesManager.dispatchValidators.count, 1)
    }

    func testDisableModule() {
        let collector = DummyCollector(config: testTealiumConfig, delegate: self, diskStorage: nil) { _ in

        }
        let dispatcher = DummyDispatcher(config: testTealiumConfig, delegate: self) { _ in

        }
        let modulesManager = ModulesManager(testTealiumConfig, dataLayer: DummyDataManagerNoData(), optionalCollectors: nil, knownDispatchers: nil)

        modulesManager.collectors = [collector]
        modulesManager.dispatchers = [dispatcher]
        XCTAssertEqual(modulesManager.collectors.count, 1)
        modulesManager.disableModule(id: "Dummy")
        XCTAssertEqual(modulesManager.collectors.count, 0)
        XCTAssertEqual(modulesManager.dispatchers.count, 1)
        modulesManager.disableModule(id: "DummyDispatcher")
        XCTAssertEqual(modulesManager.dispatchers.count, 0)

    }

    func testConnectionRestored() {
        let modulesManager = self.modulesManager
        modulesManager.collectors = []
        modulesManager.dispatchers = []
        modulesManager.dataLayerManager = DummyDataManagerNoData()

        XCTAssertEqual(modulesManager.dispatchers.count, 0)

        modulesManager.connectionRestored()

        #if os(iOS)
        XCTAssertEqual(modulesManager.dispatchers.count, 2)
        #else
        XCTAssertEqual(modulesManager.dispatchers.count, 1)
        #endif
    }

    func testSendTrack() {
        TealiumExpectations.expectations["sendTrack"] = expectation(description: "sendTrack")
        let modulesManager = self.modulesManager
        modulesManager.collectors = []
        modulesManager.dispatchers = []
        modulesManager.dataLayerManager = DummyDataManagerNoData()
        let connectivity = ConnectivityModule(config: testTealiumConfig, delegate: nil, diskStorage: nil) { _ in }
        modulesManager.dispatchManager = DummyDispatchManagerSendTrack(dispatchers: nil, dispatchValidators: nil, dispatchListeners: nil, connectivityManager: connectivity, config: testTealiumConfig)

        let track = TealiumTrackRequest(data: [:])
        modulesManager.sendTrack(track)
        wait(for: [TealiumExpectations.expectations["sendTrack"]!], timeout: 1.0)
    }

    func testRequestTrack() {
        TealiumExpectations.expectations["requestTrack"] = expectation(description: "requestTrack")
        let modulesManager = self.modulesManager
        modulesManager.collectors = []
        modulesManager.dispatchers = []
        modulesManager.dataLayerManager = DummyDataManagerNoData()
        let connectivity = ConnectivityModule(config: testTealiumConfig, delegate: nil, diskStorage: nil) { _ in }
        modulesManager.dispatchManager = DummyDispatchManagerRequestTrack(dispatchers: nil, dispatchValidators: nil, dispatchListeners: nil, connectivityManager: connectivity, config: testTealiumConfig)

        let track = TealiumTrackRequest(data: [:])
        modulesManager.sendTrack(track)
        wait(for: [TealiumExpectations.expectations["requestTrack"]!], timeout: 1.0)
    }

    func testDequeue() {
        let expect = expectation(description: "dequeue")
        let modulesManager = self.modulesManager
        modulesManager.collectors = []
        modulesManager.dispatchers = []
        modulesManager.dataLayerManager = DummyDataManagerNoData()
        let connectivity = ConnectivityModule(config: testTealiumConfig, delegate: nil, diskStorage: nil) { _ in }
        let dummyDequeue = DummyDispatchManagerdequeue(dispatchers: nil, dispatchValidators: nil, dispatchListeners: nil, connectivityManager: connectivity, config: testTealiumConfig)
        dummyDequeue.asyncExpectation = expect
        modulesManager.dispatchManager = dummyDequeue
        modulesManager.requestDequeue(reason: "test")
        wait(for: [expect], timeout: 1.0)
    }

    func testSetupDispatchListeners() {
        let collector = DummyCollector(config: testTealiumConfig, delegate: self, diskStorage: nil) { _ in

        }
        let modulesManager = self.modulesManager

        modulesManager.collectors = []
        modulesManager.dispatchListeners = []
        modulesManager.dispatchValidators = []
        let config = testTealiumConfig
        config.dispatchListeners = [collector]
        modulesManager.setupDispatchListeners(config: config)
        XCTAssertEqual(modulesManager.dispatchListeners.count, 1)
        XCTAssertTrue(modulesManager.dispatchListeners.contains(where: { ($0 as! Collector).id == "Dummy" }))
    }

    func testSetupDispatchValidators() {
        let collector = DummyCollector(config: testTealiumConfig, delegate: self, diskStorage: nil) { _ in

        }
        let modulesManager = self.modulesManager

        modulesManager.collectors = []
        modulesManager.dispatchListeners = []
        modulesManager.dispatchValidators = []
        let config = testTealiumConfig
        config.dispatchValidators = [collector]
        modulesManager.setupDispatchValidators(config: config)
        XCTAssertEqual(modulesManager.dispatchValidators.count, 1)
        XCTAssertTrue(modulesManager.dispatchValidators.contains(where: { ($0 as! Collector).id == "Dummy" }))
    }

    func testConfigPropertyUpdate() {
        let collector = DummyCollector(config: testTealiumConfig, delegate: self, diskStorage: nil) { _ in

        }
        TealiumExpectations.expectations["configPropertyUpdate"] = expectation(description: "configPropertyUpdate")
        TealiumExpectations.expectations["configPropertyUpdateModule"] = expectation(description: "configPropertyUpdateModule")
        let modulesManager = self.modulesManager

        modulesManager.collectors = [collector]
        modulesManager.dispatchListeners = []
        modulesManager.dispatchValidators = []
        let connectivity = ConnectivityModule(config: testTealiumConfig, delegate: nil, diskStorage: nil) { _ in }
        modulesManager.dispatchManager = DummyDispatchManagerConfigUpdate(dispatchers: nil, dispatchValidators: nil, dispatchListeners: nil, connectivityManager: connectivity, config: testTealiumConfig)
        let config = testTealiumConfig
        config.logLevel = .info
        modulesManager.config = config
        XCTAssertEqual(modulesManager.config, modulesManager.dispatchManager!.config)
        if let configPropertyUpdateModule = TealiumExpectations.expectations["configPropertyUpdateModule"] {
            if let configPropertyUpdate = TealiumExpectations.expectations["configPropertyUpdate"] {
                wait(for: [configPropertyUpdate, configPropertyUpdateModule], timeout: 1.0)
            } else {
                wait(for: [configPropertyUpdateModule], timeout: 1.0)
            }
            return
        } else if let configPropertyUpdate = TealiumExpectations.expectations["configPropertyUpdate"] {
            wait(for: [configPropertyUpdate], timeout: 1.0)
        }
    }

    func testSetModules() {
        let collector = DummyCollector(config: testTealiumConfig, delegate: self, diskStorage: nil) { _ in

        }
        let modulesManager = ModulesManager(testTealiumConfig, dataLayer: DummyDataManagerNoData(), optionalCollectors: nil, knownDispatchers: nil)
        modulesManager.dispatchListeners = []
        modulesManager.dispatchValidators = []
        modulesManager.dispatchers = []
        modulesManager.collectors = [collector]
        XCTAssertEqual(modulesManager.modules.count, modulesManager.collectors.count)
        modulesManager.modules = [collector, collector]
        XCTAssertEqual(modulesManager.modules.count, modulesManager.collectors.count)
        modulesManager.modules = []
        XCTAssertEqual(modulesManager.modules.count, modulesManager.collectors.count)
        XCTAssertEqual(modulesManager.modules.count, 0)
    }

    func testDispatchValidatorAddedFromConfig() {
        let validator = DummyCollector(config: testTealiumConfig, delegate: self, diskStorage: nil) { _ in

        }
        let config = testTealiumConfig
        config.dispatchValidators = [validator]
        let modulesManager = self.modulesManagerForConfig(config: config)
        XCTAssertTrue(modulesManager.dispatchValidators.contains(where: { $0.id == "Dummy" }))
    }

    func testDispatchListenerAddedFromConfig() {
        let listener = DummyCollector(config: testTealiumConfig, delegate: self, diskStorage: nil) { _ in

        }
        let config = testTealiumConfig
        config.dispatchListeners = [listener]
        let modulesManager = self.modulesManagerForConfig(config: config)
        XCTAssertTrue(modulesManager.dispatchListeners.contains(where: { ($0 as! DispatchValidator).id == "Dummy" }))
    }

    func testGatherTrackData() {
        let modulesManager = ModulesManager(testTealiumConfig, dataLayer: DummyDataManagerNoData(), optionalCollectors: nil, knownDispatchers: nil)
        modulesManager.collectors = []
        let collector = DummyCollector(config: testTealiumConfig, delegate: self, diskStorage: nil) { _ in

        }
        modulesManager.addCollector(collector)
        var data = modulesManager.gatherTrackData(for: ["testGatherTrackData": true])
        data["enabled_modules"] = nil
        XCTAssertEqual(["testGatherTrackData": true, "dummy": true], data as! [String: Bool])
        modulesManager.dataLayerManager = DummyDataManager()
        var dataWithEventData = modulesManager.gatherTrackData(for: ["testGatherTrackData": true])
        dataWithEventData["enabled_modules"] = nil
        XCTAssertEqual(["testGatherTrackData": true, "dummy": true, "eventData": true, "sessionData": true], dataWithEventData as! [String: Bool])
    }

    func testGatherTrackDataWithModulesList() {
        let modulesManager = self.modulesManager
        modulesManager.collectors = []
        modulesManager.dataLayerManager = DummyDataManagerNoData()
        let collector = DummyCollector(config: testTealiumConfig, delegate: self, diskStorage: nil) { _ in

        }
        modulesManager.addCollector(collector)
        let data = modulesManager.gatherTrackData(for: ["testGatherTrackData": true])
        XCTAssertNotNil(data["enabled_modules"]!)
        #if os(iOS)
        XCTAssertEqual(["Collect", "Dummy", "TagManagement"], data["enabled_modules"] as! [String])
        #else
        XCTAssertEqual(["Collect", "Dummy"], data["enabled_modules"] as! [String])
        #endif
        modulesManager.dataLayerManager = DummyDataManager()
        let dataWithEventData = modulesManager.gatherTrackData(for: ["testGatherTrackData": true])
        XCTAssertNotNil(dataWithEventData["enabled_modules"]!)
    }

}

extension TealiumModulesManagerTests: ModuleDelegate {
    func processRemoteCommandRequest(_ request: TealiumRequest) {

    }

    func requestTrack(_ track: TealiumTrackRequest) {

    }

    func requestDequeue(reason: String) {

    }

}

class DummyDispatchManagerRequestTrack: DispatchManagerProtocol {
    var dispatchers: [Dispatcher]?

    var dispatchListeners: [DispatchListener]?

    var dispatchValidators: [DispatchValidator]?

    var config: TealiumConfig {
        willSet {
            TealiumExpectations.expectations["configPropertyUpdate"]?.fulfill()
        }
    }

    required init(dispatchers: [Dispatcher]?, dispatchValidators: [DispatchValidator]?, dispatchListeners: [DispatchListener]?, connectivityManager: ConnectivityModule, config: TealiumConfig) {
        self.dispatchers = dispatchers
        self.dispatchValidators = dispatchValidators
        self.dispatchListeners = dispatchListeners
        self.config = config
    }

    func processTrack(_ request: TealiumTrackRequest) {
        XCTAssertTrue(request.trackDictionary.count > 0)
        XCTAssertNotNil(request.trackDictionary["request_uuid"])
        TealiumExpectations.expectations["requestTrack"]?.fulfill()
    }

    func handleDequeueRequest(reason: String) {
    }

}

class DummyDispatchManagerSendTrack: DispatchManagerProtocol {
    var dispatchers: [Dispatcher]?

    var dispatchListeners: [DispatchListener]?

    var dispatchValidators: [DispatchValidator]?

    var config: TealiumConfig {
        willSet {
            TealiumExpectations.expectations["configPropertyUpdate"]?.fulfill()
        }
    }

    required init(dispatchers: [Dispatcher]?, dispatchValidators: [DispatchValidator]?, dispatchListeners: [DispatchListener]?, connectivityManager: ConnectivityModule, config: TealiumConfig) {
        self.dispatchers = dispatchers
        self.dispatchValidators = dispatchValidators
        self.dispatchListeners = dispatchListeners
        self.config = config
    }

    func processTrack(_ request: TealiumTrackRequest) {
        XCTAssertTrue(request.trackDictionary.count > 0)
        XCTAssertNotNil(request.trackDictionary["request_uuid"])
        TealiumExpectations.expectations["sendTrack"]?.fulfill()
    }

    func handleDequeueRequest(reason: String) {

    }

}
