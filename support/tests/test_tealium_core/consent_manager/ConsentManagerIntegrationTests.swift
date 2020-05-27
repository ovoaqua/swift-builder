//
//  ConsentManagerIntegrationTests.swift
//  tealium-swift
//
//  Created by Craig Rouse on 01/05/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumCore
import XCTest

class ConsentManagerTests: XCTestCase {
    var consentManager: TealiumConsentManager?
    let tealHelper = TestTealiumHelper()
    var config: TealiumConfig!
    var expectations = [XCTestExpectation]()
    var trackData: [String: Any]?
    let waiter = XCTWaiter()
    var allTestsFinished = false

    override func setUp() {
        super.setUp()
        expectations = [XCTestExpectation]()
        config = tealHelper.getConfig()
        initState()
        allTestsFinished = false
    }

    override func tearDown() {
        super.tearDown()
        deInitState()
        allTestsFinished = false
    }

    func initState() {
        consentManager = nil
        consentManager = TealiumConsentManager(config: config, delegate: self, diskStorage: ConsentMockDiskStorage(), nil)
        consentManager?.resetUserConsentPreferences()
    }

    func deInitState() {
        consentManager?.resetUserConsentPreferences()
        consentManager = nil
    }

    func getExpectation(forDescription: String) -> XCTestExpectation? {
        let exp = expectations.filter {
            $0.description == forDescription
        }
        if exp.count > 0 {
            return exp[0]
        }
        return nil
    }
    
    // note: in some cases this test fails due to slow clearing of persistent data
    // to get around this, test has been renamed to make sure it runs first (always run in alphabetical order)
    // thoroughly tested, and comfortable that this is an issue with UserDefaults clearing slowly under test on the simulator
    func testAStartDefault() {
        consentManager = TealiumConsentManager(config: config, delegate: tealHelper, diskStorage: ConsentMockDiskStorage()) {
            XCTAssertTrue(self.consentManager?.getUserConsentStatus() == .unknown, "Consent Manager Test: \(#function) - Incorrect initial state: " + (self.consentManager?.getUserConsentStatus().rawValue ?? ""))
        }
    }

    func testConsentStoreConfigFromDictionary() {
        let categories = ["cdp", "analytics"]
        let status = "consented"
        let consentDictionary: [String: Any] = [TealiumConsentConstants.consentCategoriesKey: categories, TealiumConsentConstants.trackingConsentedKey: status]
        var consentUserPreferences = TealiumConsentUserPreferences(consentStatus: .unknown, consentCategories: nil)
        consentUserPreferences.initWithDictionary(preferencesDictionary: consentDictionary)
        XCTAssertNotNil(consentUserPreferences, "Consent Manager Test: \(#function) - Consent Preferences could not be initialized from dictionary")
        XCTAssertTrue(consentUserPreferences.consentStatus == .consented, "Consent Manager Test: \(#function) - Consent Preferences contained unexpected status")
        XCTAssertTrue(consentUserPreferences.consentCategories == [.cdp, .analytics], "Consent Manager Test: \(#function) - Consent Preferences contained unexpected status")
    }

    func testTrackUserConsentPreferences() {
        let expectation = self.expectation(description: "testTrackUserConsentPreferences")
        expectations.append(expectation)
        consentManager?.setModuleDelegate(delegate: self)
        consentManager?.consentLoggingEnabled = true
        let consentPreferences = TealiumConsentUserPreferences(consentStatus: .consented, consentCategories: [.cdp])
        consentManager?.trackUserConsentPreferences(preferences: consentPreferences)
        waiter.wait(for: expectations, timeout: 2)
    }

    func testloadSavedPreferencesEmpty() {
        let preferencesConfig = consentManager?.getSavedPreferences()
        XCTAssertTrue(preferencesConfig == nil, "Consent Manager Test: \(#function) -Preferences unexpectedly contained a value")
    }

    // check that persistent saved preferences contains values passed in config object
    func testloadSavedPreferencesExistingPersistentData() {
        consentManager = TealiumConsentManager(config: config, delegate: tealHelper, diskStorage: ConsentMockDiskStorage()) {
            self.consentManager?.setUserConsentStatus(.consented)
            self.consentManager?.setUserConsentCategories([.cdp, .analytics])
            if let savedConfig = self.consentManager?.getSavedPreferences() {
                let categories = savedConfig.consentCategories, status = savedConfig.consentStatus
                XCTAssertTrue(categories == [.cdp, .analytics], "Consent Manager Test: \(#function) -Incorrect array members found for categories")
                XCTAssertTrue(status == .consented, "Consent Manager Test: \(#function) -Incorrect consent status found")
            }
        }
    }

    // note: can sometimes fail when run with other tests due to multiple resets being in queue
    // this is not believed to be a problem; it runs fine in isolation.
    // extensively tested
    func testStoreUserConsentPreferences() {
        consentManager = TealiumConsentManager(config: config, delegate: tealHelper, diskStorage: ConsentMockDiskStorage()) {
            let preferences = TealiumConsentUserPreferences(consentStatus: .consented, consentCategories: [.cdp, .analytics])
            self.consentManager?.setConsentUserPreferences(preferences)
            self.consentManager?.storeConsentUserPreferences()
            let savedPreferences = self.consentManager?.getSavedPreferences()
            if let categories = savedPreferences?.consentCategories, let status = savedPreferences?.consentStatus {
                XCTAssertTrue(categories == [.cdp, .analytics], "Consent Manager Test: \(#function) -Incorrect array members found for categories")
                XCTAssertTrue(status == .consented, "Consent Manager Test: \(#function) -Incorrect consent status found")
            } else {
                XCTFail("Saved consent preferences was nil")
            }
        }
    }

    func testCanUpdateCategories() {
        consentManager = TealiumConsentManager(config: config, delegate: tealHelper, diskStorage: ConsentMockDiskStorage()) {
            self.consentManager?.resetUserConsentPreferences()
            self.consentManager?.setUserConsentCategories([.cdp, .analytics])
            XCTAssertTrue(self.consentManager?.getSavedPreferences()?.consentCategories == [.cdp, .analytics])
            self.consentManager?.setUserConsentCategories([.bigData])
            XCTAssertTrue(self.consentManager?.getSavedPreferences()?.consentCategories == [.bigData])
        }
    }

    func testCanUpdateStatus() {
        consentManager = TealiumConsentManager(config: config, delegate: tealHelper, diskStorage: ConsentMockDiskStorage()) {
            self.consentManager?.resetUserConsentPreferences()
            self.consentManager?.setUserConsentStatus(.consented)
            self.consentManager?.setUserConsentStatus(.notConsented)
            XCTAssertTrue(self.consentManager?.getSavedPreferences()?.consentStatus == .notConsented)
        }
    }

    func testGetTrackingStatusWhenNotConsented() {
        consentManager = TealiumConsentManager(config: config, delegate: tealHelper, diskStorage: ConsentMockDiskStorage()) {
            self.consentManager?.setUserConsentStatus(.notConsented)
            if let _ = self.consentManager?.getSavedPreferences() {
                XCTAssertTrue(self.consentManager?.getTrackingStatus() == .trackingForbidden, "Consent Manager Test: \(#function) - getTrackingStatus returned unexpected value")
            }
        }
    }
    
    func testGetTrackingStatusWhenConsented() {
        consentManager = TealiumConsentManager(config: config, delegate: tealHelper, diskStorage: ConsentMockDiskStorage()) {
            self.consentManager?.setUserConsentCategories([.analytics, .cookieMatch])
            if let _ = self.consentManager?.getSavedPreferences() {
                XCTAssertTrue(self.consentManager?.getTrackingStatus() == .trackingAllowed, "Consent Manager Test: \(#function) - getTrackingStatus returned unexpected value")
            }
        }
    }

    func testSetConsentStatus() {
        consentManager?.setUserConsentStatus(.notConsented)
        XCTAssertTrue(consentManager?.getUserConsentStatus() == .notConsented, "Consent Manager Test: \(#function) - unexpected consent status")
        XCTAssertTrue(consentManager?.getUserConsentCategories() == [TealiumConsentCategories](), "Consent Manager Test: \(#function) - unexpectedly found consent categories")
    }

    func testSetConsentCategories() {
        consentManager?.setUserConsentCategories([.affiliates])
        XCTAssertTrue(consentManager?.getUserConsentStatus() == .consented, "Consent Manager Test: \(#function) - unexpected consent status")
        XCTAssertTrue(consentManager?.getUserConsentCategories() == [.affiliates], "Consent Manager Test: \(#function) -  unexpected consent categories found")
    }

    func testResetUserConsentPreferences() {
        consentManager?.setUserConsentStatus(.consented)
        consentManager?.setUserConsentCategories([.cdp])
        consentManager?.resetUserConsentPreferences()
        XCTAssertTrue(consentManager?.getSavedPreferences() == nil, "Consent Manager Test: \(#function) - unexpected config found")
        XCTAssertTrue(consentManager?.getUserConsentStatus() == .unknown, "Consent Manager Test: \(#function) - unexpected status found")
        XCTAssertTrue(consentManager?.getUserConsentCategories() == nil, "Consent Manager Test: \(#function) - unexpected categories found")
    }
    
    func testShouldDropTrackingCall() {
        let track = TealiumTrackRequest(data: ["dummy": "true"], completion: nil)
        config.enableConsentManager = true
        let consentManagerModule = TealiumConsentManagerModule(config: config, delegate: self, diskStorage: ConsentMockDiskStorage(), completion: { _ in })
        let localConsentManager = consentManagerModule.consentManager
        localConsentManager?.setUserConsentStatus(.notConsented)
        consentManagerModule.ready = true
        let shouldDrop = consentManagerModule.shouldDrop(request: track)
        XCTAssertTrue(shouldDrop)
    }

    func testShouldQueueTrackingCall() {
        let track = TealiumTrackRequest(data: ["dummy": "true"], completion: nil)
        config.enableConsentManager = true
        let consentManagerModule = TealiumConsentManagerModule(config: config, delegate: self, diskStorage: ConsentMockDiskStorage(), completion: { _ in })
        let localConsentManager = consentManagerModule.consentManager
        localConsentManager?.setUserConsentStatus(.unknown)
        consentManagerModule.ready = true
        let queue = consentManagerModule.shouldQueue(request: track)
        XCTAssertTrue(queue.0)
    }

    func testShouldNotQueueTrackingCall() {
        let track = TealiumTrackRequest(data: ["dummy": "true"], completion: nil)
        let consentManagerModule = TealiumConsentManagerModule(config: TestTealiumHelper().getConfig(), delegate: self, diskStorage: ConsentMockDiskStorage(), completion: { _ in })
        let localConsentManager = consentManagerModule.consentManager
        localConsentManager?.setUserConsentStatus(.consented)
        consentManagerModule.ready = true
        let queue = consentManagerModule.shouldQueue(request: track)
        XCTAssertFalse(queue.0)
    }

    // MARK: Consent Convenience Methods
    func testConsentStatusConsentedSetsAllCategoryNames() {
        consentManager?.setUserConsentStatus(.consented)
        XCTAssertTrue(consentManager?.getUserConsentCategories() == TealiumConsentCategories.all())
        XCTAssertTrue(consentManager?.getUserConsentCategories()?.count == TealiumConsentCategories.all().count)
    }

    func testNotConsentedRemovesAllCategoryNames() {
        consentManager?.setUserConsentStatus(.consented)
        consentManager?.setUserConsentStatus(.notConsented)
        guard let categories = consentManager?.getUserConsentCategories() else {
            XCTFail("Categories should return at least empty array")
            return
        }
        XCTAssertTrue(categories.isEmpty)
    }

    func testConsentStatusIsConsentedIfCategoriesAreSet() {
        consentManager?.setUserConsentStatus(.notConsented)
        consentManager?.setUserConsentCategories([.analytics])
        XCTAssertTrue(consentManager?.getUserConsentStatus() == .consented)
    }
    
    func testConsentStatusIsUknownIfNoStatusSet() {
        XCTAssertTrue(consentManager?.getUserConsentStatus() == .unknown)
    }
    
    func testGetUserConsentCategoriesOnceSet() {
        consentManager?.setUserConsentCategories([.analytics, .bigData])
        XCTAssertTrue(consentManager?.getUserConsentCategories() == [.analytics, .bigData])
    }
    
    func testConsentCategoriesEqual() {
        var lhs: [TealiumConsentCategories] = [.analytics, .bigData]
        let rhs: [TealiumConsentCategories] = [.analytics, .bigData]
        var result = consentManager?.consentCategoriesEqual(lhs, rhs)
        XCTAssertTrue(result!)
        
        lhs = [.affiliates, .email]
        result = consentManager?.consentCategoriesEqual(lhs, rhs)
        XCTAssertFalse(result!)
    }
    
    func testSetUserConsentPreferences() {
        let expectedUserConsentPreferences = TealiumConsentUserPreferences(consentStatus: .consented, consentCategories: [.analytics, .engagement])
        consentManager?.setConsentUserPreferences(expectedUserConsentPreferences)
        let actualUserConsentPreferences = consentManager?.getUserConsentPreferences()
        XCTAssertEqual(actualUserConsentPreferences, expectedUserConsentPreferences)
    }
}

extension ConsentManagerTests: TealiumModuleDelegate {
    func requestReleaseQueue(reason: String) { }
    
    func requestTrack(_ track: TealiumTrackRequest) {
        trackData = track.trackDictionary
        if trackData?["tealium_event"] as? String == TealiumKey.updateConsentCookieEventName {
            return
        }
        if let testtrackUserConsentPreferencesExpectation = getExpectation(forDescription: "testTrackUserConsentPreferences") {
            if let categories = trackData?["consent_categories"] as? [String], categories.count > 0 {
                let catEnum = TealiumConsentCategories.consentCategoriesStringArrayToEnum(categories)
                XCTAssertTrue([TealiumConsentCategories.cdp] == catEnum, "Consent Manager Test: testTrackUserConsentPreferences: Categories array contained unexpected values")
            }
            if allTestsFinished {
                testtrackUserConsentPreferencesExpectation.fulfill()
            }
    }

}
