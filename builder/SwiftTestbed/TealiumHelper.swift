//
//  TealiumHelper.swift
//  SwiftTestbed
//
//  Created by Jason Koo on 11/22/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumCore
import TealiumCollect
import TealiumConnectivity
import TealiumAttribution
import TealiumConsentManager
import TealiumDispatchQueue
import TealiumDelegate
import TealiumDeviceData
import TealiumRemoteCommands
import TealiumTagManagement
import TealiumPersistentData
import TealiumVolatileData
import TealiumVisitorService
import TealiumLocation
import TealiumLifecycle

extension String: Error {}

/// Example of a shared helper to handle all 3rd party tracking services. This
/// paradigm is recommended to reduce burden of future code updates for external services
/// in general.
/// Note: TealiumHelper class inherits from NSObject to allow @objc annotations and Objective-C interop.
/// If you don't need this, you may omit @objc annotations and NSObject inheritance.
class TealiumHelper: NSObject {

    static let shared = TealiumHelper()
    var tealium: Tealium?
    var enableHelperLogs = false
    var traceId = "04136"

    override private init () {

    }

    func start() {
        // REQUIRED Config object for lib
        let config = TealiumConfig(account: "tealiummobile",
                                   profile: "demo",
                                   environment: "qa",
                                   datasource: "test12",
                                   optionalData: nil)

        config.connectivityRefreshInterval = 5
        config.logLevel = .verbose
        config.consentLoggingEnabled = true
        config.searchAdsEnabled = true
        config.initialUserConsentStatus = .consented
        config.shouldAddCookieObserver = false
        config.shouldUseRemotePublishSettings = true
        config.batchSize = 5
        config.dispatchAfter = 5
//        config.dispatchQueueLimit = 200
        config.batchingEnabled = true
        config.visitorServiceRefreshInterval = 0
        config.visitorServiceOverrideProfile = "main"
        // OPTIONALLY add an external delegate
        config.addDelegate(self)
        config.memoryReportingEnabled = true

        #if AUTOTRACKING
//        print("*** TealiumHelper: Autotracking enabled.")
        #else
        // OPTIONALLY disable a particular module by name
        
        let list = TealiumModulesList(isWhitelist: false,
                                      moduleNames: ["autotracking"])
        config.modulesList = list
        config.diskStorageEnabled = true
        config.addVisitorServiceDelegate(self)
        config.remoteAPIEnabled = true
        config.logLevel = .verbose
        config.batterySaverEnabled = true
        config.geofenceUrl = "https://tags.tiqcdn.com/dle/tealiummobile/location/geofences.json"
        #endif
        #if os(iOS)
        
        let remoteCommand = TealiumRemoteCommand(commandId: "hello",
                                                 description: "test") { response in
                                                    if TealiumHelper.shared.enableHelperLogs {
//                                                        print("*** TealiumHelper: Remote Command Executed: response:\(response)")
                                                    }
                                                    let dict = ["hello":"from helper"]
                                                    // set some JSON response data to be passed back to the webview
                                                    let myJson = try? JSONSerialization.data(withJSONObject: dict, options: [])
                                                    response.data = myJson
        }
        config.addRemoteCommand(remoteCommand)
        #endif

        // REQUIRED Initialization
        tealium = Tealium(config: config) { [weak self] response in
        // Optional processing post init.
        // Optionally, join a trace. Trace ID must be generated server-side in UDH.
//        self.tealium?.leaveTrace(killVisitorSession: true)
        self?.tealium?.persistentData()?.add(data: ["testPersistentKey": "testPersistentValue"])
            
        self?.tealium?.persistentData()?.deleteData(forKeys: ["user_name", "testPersistentKey", "newPersistentKey"])
            
                            self?.tealium?.persistentData()?.add(data: ["newPersistentKey": "testPersistentValue"])
                            self?.tealium?.volatileData()?.add(data: ["testVolatileKey": "testVolatileValue"])
            
            print("Persistent Data: \(String(describing: self?.tealium?.persistentData()?.dictionary))")
            
            print("Lifecycle Data: \(String(describing: self?.tealium?.lifecycle()?.dictionary))")
        }
    }

    func track(title: String, data: [String: Any]?) {
        tealium?.track(title: title,
                       data: data,
                       completion: { (success, info, error) in
                        // Optional post processing
                        if self.enableHelperLogs == false {
                            return
                        }
        })
    }

    func trackView(title: String, data: [String: Any]?) {
        tealium?.trackView(title: title,
                       data: data,
                       completion: { (success, info, error) in
                        // Optional post processing
                        if self.enableHelperLogs == false {
                            return
                        }
        })

    }
    
    func joinTrace(_ traceID: String) {
        self.tealium?.joinTrace(traceId: traceID)
    }

    func leaveTrace() {
        self.tealium?.leaveTrace()
    }
    
    func crash() {
        NSException.raise(NSExceptionName(rawValue: "Exception"), format: "This is a test exception", arguments: getVaList(["nil"]))
    }
}

extension TealiumHelper: TealiumDelegate {

    func tealiumShouldTrack(data: [String: Any]) -> Bool {
        return true
    }

    func tealiumTrackCompleted(success: Bool, info: [String: Any]?, error: Error?) {
        if enableHelperLogs == false {
            return
        }
        print("\n*** Tealium Helper: Tealium Delegate : tealiumTrackCompleted *** Track finished. Was successful:\(success)\nInfo:\(info as AnyObject)\((error != nil) ? "\nError:\(String(describing: error))":"")")
    }
}

extension TealiumHelper: TealiumVisitorServiceDelegate {
    func didUpdate(visitor profile: TealiumVisitorProfile) {
        if let json = try? JSONEncoder().encode(profile), let string = String(data: json, encoding: .utf8) {
            if self.enableHelperLogs {
                print(string)
            }
        }
    }
    
}
