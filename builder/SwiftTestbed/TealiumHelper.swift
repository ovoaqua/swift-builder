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
import TealiumTagManagement
import TealiumAttribution
//import TealiumAutotracking
import TealiumRemoteCommands
import TealiumVisitorService
import TealiumLifecycle
import TealiumLocation

extension String: Error {}

/// Example of a shared helper to handle all 3rd party tracking services. This
/// paradigm is recommended to reduce burden of future code updates for external services
/// in general.
/// Note: TealiumHelper class inherits from NSObject to allow @objc annotations and Objective-C interop.
/// If you don't need this, you may omit @objc annotations and NSObject inheritance.
class TealiumHelper: NSObject {

    static let shared = TealiumHelper()
    var tealium: Tealium?
    var enableHelperLogs = true

    override private init () {

    }

    func start() {
        // REQUIRED Config object for lib
        let config = TealiumConfig(account: "tealiummobile",
                                   profile: "demo",
                                   environment: "dev",
                                   dataSource: "test12",
                                   options: nil)
        config.connectivityRefreshInterval = 5
        config.loggerType = .os
        config.logLevel = .info
        config.consentPolicy = nil
        config.consentLoggingEnabled = true
        config.dispatchListeners = [self]
//        config.dispatchValidators = [self]
        config.searchAdsEnabled = true
//        config.appDelegateProxyEnabled = false
        config.shouldUseRemotePublishSettings = false
        //config.batchingEnabled = true
        //config.batchSize = 5
        config.memoryReportingEnabled = true
        config.diskStorageEnabled = true
        config.visitorServiceDelegate = self
        config.memoryReportingEnabled = true
        config.batterySaverEnabled = true
        config.remoteAPIEnabled = true
        config.collectors = [
            MyDateCollector.self,
//            Collectors.Attribution,
                             Collectors.Lifecycle,
                             Collectors.AppData,
                             Collectors.Connectivity,
 //                            Collectors.Crash,
                             Collectors.Device,
                             Collectors.Location,
                             Collectors.VisitorService,
        ]
        
        config.hostedDataLayerKeys = ["hdl-test": "product_id"]
        
        config.dispatchers = [
            Dispatchers.Collect,
//                              MyCustomDispatcher.self,
                              Dispatchers.TagManagement,
                              Dispatchers.RemoteCommands
        ]
//        tealium?.dataLayerManager
        config.geofenceUrl = "https://tags.tiqcdn.com/dle/tealiummobile/location/geofences.json"

        #if os(iOS)
        let remoteCommand = RemoteCommand(commandId: "display", description: "Test") { response in
            guard let payload = response.payload,
                  let hello = payload["hello"] as? String,
                let key = payload["key"] as? String,
                let tealium = payload["tealium"] as? String else {
                print("Remote Command didnt work 👎")
                return
            }
            print("Remote Command data: hello = \(hello), key = \(key), tealium = \(tealium) 🎉🎊")
        }
        config.addRemoteCommand(remoteCommand)
        #endif
//        config.diskStorageDirectory = .documents
//        config.loggerType = .custom(<#T##TealiumLoggerProtocol#>)
        tealium = Tealium(config: config) { [weak self] response in
            guard let self = self,
                let teal = self.tealium else {
                return
                
            }

            let dataLayer = teal.dataLayer
            teal.consentManager?.userConsentStatus = .consented
            dataLayer.add(key: "myvarforever", value: 123456, expiry: .forever)

            dataLayer.add(data: ["some_key1": "some_val1"], expiry: .session)

            dataLayer.add(data: ["some_key_forever":"some_val_forever"], expiry: .forever) // forever

            dataLayer.add(data: ["until": "restart"], expiry: .untilRestart)

            dataLayer.add(data: ["custom": "expire in 3 min"], expiry: .afterCustom((.minutes, 3)))

            dataLayer.delete(for: ["myvarforever"])

            dataLayer.add(data: ["hello": "world"], expiry: .untilRestart)

            dataLayer.add(key: "test", value: 123, expiry: .session)

            dataLayer.delete(for: ["hello", "test"])

            dataLayer.add(key: "hello", value: "itsme", expiry: .afterCustom((.months, 1)))

            teal.location?.requestAuthorization()
        }
        
//        #if os(iOS)
//        guard let remoteCommands = tealium?.remoteCommands else {
//            return
//        }
//        let remoteCommand = RemoteCommand(commandId: "display", description: "Test") { response in
//            let payload = response.payload()
//            guard let hello = payload["hello"] as? String,
//                let key = payload["key"] as? String,
//                let tealium = payload["tealium"] as? String else {
//                print("Remote Command didnt work 👎 \(payload)")
//                return
//            }
//            print("Remote Command data: hello = \(hello), key = \(key), tealium = \(tealium) 🎉🎊")
//        }
//        remoteCommands.add(remoteCommand)
//        #endif
        
        
    }
    
    func resetConsentPreferences() {
        tealium?.consentManager?.resetUserConsentPreferences()
    }
    
    func toggleConsentStatus() {
        if let consentStatus = tealium?.consentManager?.userConsentStatus {
            switch consentStatus {
            case .consented:
                TealiumHelper.shared.tealium?.consentManager?.userConsentStatus = .notConsented
            default:
                TealiumHelper.shared.tealium?.consentManager?.userConsentStatus = .consented
            }
        }
    }

    func track(title: String, data: [String: Any]?) {
        let dispatch = TealiumEvent(title, dataLayer: data)
        tealium?.track(dispatch)
    }

    func trackView(title: String, data: [String: Any]?) {
        let dispatch = TealiumView(title, dataLayer: data)
        tealium?.track(dispatch)

    }
    
    func joinTrace(_ traceID: String) {
        self.tealium?.joinTrace(id: traceID)
    }

    func leaveTrace() {
        self.tealium?.leaveTrace()
    }
    
    func crash() {
        NSException.raise(NSExceptionName(rawValue: "Exception"), format: "This is a test exception", arguments: getVaList(["nil"]))
    }
}

extension TealiumHelper: VisitorServiceDelegate {
    func didUpdate(visitorProfile: TealiumVisitorProfile) {
        if let json = try? JSONEncoder().encode(visitorProfile), let string = String(data: json, encoding: .utf8) {
            if self.enableHelperLogs {
                print(string)
            }
        }
    }

}

extension TealiumHelper: DispatchListener {
    public func willTrack(request: TealiumRequest) {
        print("helper - willtrack")
    }
}

extension TealiumHelper: DispatchValidator {
    var id: String {
        return "Helper"
    }

    func shouldQueue(request: TealiumRequest) -> (Bool, [String : Any]?) {
        (false, nil)
    }

    func shouldDrop(request: TealiumRequest) -> Bool {
        false
    }

    func shouldPurge(request: TealiumRequest) -> Bool {
        false
    }


}

class MyDateCollector: Collector {
    
    var id = "MyDateCollector"
    
    var data: [String : Any]? {
        ["day_of_week": dayOfWeek]
    }
    
    var config: TealiumConfig
    
    
    required init(config: TealiumConfig,
                  delegate: ModuleDelegate?,
                  diskStorage: TealiumDiskStorageProtocol?,
                  completion: (ModuleResult) -> Void) {
        self.config = config
    }
    
    
    var dayOfWeek: String {
        return "\(Calendar.current.dateComponents([.weekday], from: Date()).weekday ?? -1)"
    }

}


class MyCustomDispatcher: Dispatcher {
    
    var id = "MyCustomDispatcher"
    
    var config: TealiumConfig
    
    required init(config: TealiumConfig, delegate: ModuleDelegate, completion: ModuleCompletion?) {
        self.config = config
    }
    
    func dynamicTrack(_ request: TealiumRequest, completion: ModuleCompletion?) {
        switch request {
        case let request as TealiumTrackRequest:
            print("Track received: \(request.event ?? "no event name")")
            // perform track action, e.g. send to custom endpoint
        case _ as TealiumBatchTrackRequest:
            print("Batch track received")
            // perform batch track action, e.g. send to custom endpoint
        default:
            return
        }
    }
}
