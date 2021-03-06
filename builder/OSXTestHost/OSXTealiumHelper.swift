//
//  OSXTealiumHelper.swift
//  SwiftTestbed
//
//  Created by Jason Koo on 11/22/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumCore
import TealiumCollect
import TealiumConnectivity
import ConsentManager
import TealiumDispatchQueue
import TealiumDelegate
import DeviceData
import TealiumPersistentData
import TealiumVolatileData
import TealiumVisitorService

extension String: Error {}

/// Example of a shared helper to handle all 3rd party tracking services. This
/// paradigm is recommended to reduce burden of future code updates for external services
/// in general.
/// Note: OSXTealiumHelper class inherits from NSObject to allow @objc annotations and Objective-C interop.
/// If you don't need this, you may omit @objc annotations and NSObject inheritance.
class OSXTealiumHelper: NSObject {

    static let shared = OSXTealiumHelper()
    var tealium: Tealium?
    var enableHelperLogs = false
    var traceId = "04136"

    override private init () {

    }

    func start() {
        // REQUIRED Config object for lib
        let config = TealiumConfig(account: "tealiummobile",
                                   profile: "demo",
                                   environment: "dev",
                                   datasource: "test12",
                                   options: nil)

        // OPTIONALLY set log level
        config.setConnectivityRefreshInterval(5)
        config.setLogLevel(.verbose)
        config.consentLoggingEnabled = true
        config.enableConsentManager = true
        //config.setBatchSize(5)
        //config.setDispatchAfter(numberOfEvents: 5)
        config.setMaxQueueSize(200)
        config.setIsEventBatchingEnabled(false)
//        config.setVisitorServiceRefresh(interval: 0)
//        config.setVisitorServiceOverrideProfile("main")
        // OPTIONALLY add an external delegate
        config.addDelegate(self)
        config.setMemoryReportingEnabled(true)

        #if AUTOTRACKING
//        print("*** OSXTealiumHelper: Autotracking enabled.")
        #else
        // OPTIONALLY disable a particular module by name
        
        let list = TealiumModulesList(isWhitelist: false,
                                      moduleNames: ["autotracking"])
        config.setModulesList(list)
        config.setDiskStorageEnabled(isEnabled: true)
        config.addVisitorServiceDelegate(self)
        #endif


        // REQUIRED Initialization
        tealium = Tealium(config: config) { response in
        // Optional processing post init.
        // Optionally, join a trace. Trace ID must be generated server-side in UDH.
//        self.tealium?.leaveTrace(killVisitorSession: true)
        self.tealium?.persistentData()?.add(data: ["testPersistentKey": "testPersistentValue"])
            
        self.tealium?.persistentData()?.deleteData(forKeys: ["user_name", "testPersistentKey", "newPersistentKey"])
            
                            self.tealium?.persistentData()?.add(data: ["newPersistentKey": "testPersistentValue"])
                            self.tealium?.volatileData()?.add(data: ["testVolatileKey": "testVolatileValue"])

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

extension OSXTealiumHelper: TealiumDelegate {

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

extension OSXTealiumHelper: TealiumVisitorServiceDelegate {
    func didUpdate(visitorProfile: TealiumVisitorProfile) {
        if let json = try? JSONEncoder().encode(visitorProfile), let string = String(data: json, encoding: .utf8) {
            if self.enableHelperLogs {
                print(string)
            }
        }
    }
    
}
