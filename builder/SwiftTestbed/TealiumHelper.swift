//
//  TealiumHelper.swift
//  SwiftTestbed
//
//  Created by Jason Koo on 11/22/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumCore
//import TealiumCrash2
import TealiumCollect
import TealiumTagManagement
import TealiumAttribution
import TealiumRemoteCommands
import TealiumVisitorService
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
    var logger: TealiumLoggerProtocol?

    override private init () {

    }

    func start() {
        // REQUIRED Config object for lib
        let config = TealiumConfig(account: "tealiummobile",
                                   profile: "demo",
                                   environment: "dev",
                                   datasource: "test12",
                                   optionalData: nil)
        config.connectivityRefreshInterval = 5
        config.loggerType = .os
        config.logLevel = .info
//        config.consentLoggingEnabled = true
        config.searchAdsEnabled = true
//        config.initialUserConsentStatus = .consented
//        config.shouldAddCookieObserver = false
        config.shouldUseRemotePublishSettings = false
        // config.batchSize = 5
        // config.dispatchAfter = 5
        // config.dispatchQueueLimit = 200
        // config.batchingEnabled = true
        // config.visitorServiceRefreshInterval = 0
        // config.visitorServiceOverrideProfile = "main"
        // OPTIONALLY add an external delegate
        config.addDelegate(self)
        config.memoryReportingEnabled = true

        #if AUTOTRACKING
//        print("*** TealiumHelper: Autotracking enabled.")
        #else
        // OPTIONALLY disable a particular module by name
        
        let list = TealiumModulesList(isWhitelist: false,
                                      moduleNames: [.autotracking, .consentmanager])
        config.modulesList = list
        config.diskStorageEnabled = true
        //config.visitorServiceDelegate = self
        config.remoteAPIEnabled = true
//        config.logLevel = .verbose
        config.shouldCollectTealiumData = true
        config.batterySaverEnabled = true
        logger = config.logger
        //config.geofenceUrl = "https://tags.tiqcdn.com/dle/tealiummobile/location/geofences.json"
        #endif
//        #if os(iOS)
//
//        let remoteCommand = TealiumRemoteCommand(commandId: "hello",
//                                                 description: "test") { response in
//                                                    if TealiumHelper.shared.enableHelperLogs {
////                                                        print("*** TealiumHelper: Remote Command Executed: response:\(response)")
//                                                    }
//                                                    let dict = ["hello":"from helper"]
//                                                    // set some JSON response data to be passed back to the webview
//                                                    let myJson = try? JSONSerialization.data(withJSONObject: dict, options: [])
//                                                    response.data = myJson
//        }
//        config.addRemoteCommand(remoteCommand)
//        #endif
        
        // REQUIRED Initialization
        tealium = Tealium(config: config) { [weak self] response in
            guard let self = self, let teal = self.tealium else { return }
            
            self.track(title: "init", data: nil)
            
            let persitence = teal.persistentData()
            let sessionPersistence = teal.volatileData()
            let dataManager = teal.eventDataManager
                
            //dataManager.add(key: "myvarforever", value: 123456, expiration: .forever)
                        
            //persitence.add(data: ["some_key1": "some_val1"], expiration: .session)
            
            //persitence.add(data: ["some_key_forever":"some_val_forever"]) // forever
            
            // persitence.add(data: ["until": "restart"], expiration: .untilRestart)
            
            //persitence.add(data: ["custom": "expire in 3 min"], expiration: .afterCustom((.minutes, 3)))
   
            //persitence.deleteData(forKeys: ["myvarforever"])
            
//            sessionPersistence.add(data: ["hello": "world"]) // session

//            sessionPersistence.add(value: 123, forKey: "test") // session

            //sessionPersistence.deleteData(forKeys: ["hello", "test"])
            
            persitence.add(value: "hello", forKey: "itsme", expiration: .afterCustom((.months, 1)))
            
            print("Volatile Data: \(String(describing: sessionPersistence.dictionary))")

            print("Persistent Data: \(String(describing: persitence.dictionary))")

        }
    }

    func track(title: String, data: [String: Any]?) {
//        tealium?.lifecycle()?.launch(at: Date())
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
        let logRequest = TealiumLogRequest(title: "😀Track data", message: "", info: data, logLevel: .info, category: .general)
        logger?.log(logRequest)
        return true
    }

    func tealiumTrackCompleted(success: Bool, info: [String: Any]?, error: Error?) {
        if enableHelperLogs == false {
            return
        }
        print("\n*** Tealium Helper: Tealium Delegate : tealiumTrackCompleted *** Track finished. Was successful:\(success)\nInfo:\(info as AnyObject)\((error != nil) ? "\nError:\(String(describing: error))":"")")
    }
}

//extension TealiumHelper: TealiumVisitorServiceDelegate {
//    func didUpdate(visitorProfile: TealiumVisitorProfile) {
//        if let json = try? JSONEncoder().encode(visitorProfile), let string = String(data: json, encoding: .utf8) {
//            if self.enableHelperLogs {
//                print(string)
//            }
//        }
//    }
//
//}
