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
import TealiumRemoteCommands
import TealiumVisitorService
import TealiumLifecycle
import TealiumLocation
import TealiumAutotracking

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
    var traceId = "04136"
    var logger: TealiumLoggerProtocol?

    override private init () {

    }

    func start() {
        // REQUIRED Config object for lib
        let config = TealiumConfig(account: "tealiummobile",
                                   profile: "ccpa-test",
                                   environment: "dev",
                                   dataSource: "test12",
                                   options: nil)
        config.connectivityRefreshInterval = 5
        config.loggerType = .os
        config.logLevel = .debug
        config.consentPolicy = nil
        config.consentLoggingEnabled = true
        config.dispatchListeners = [self]
        config.dispatchValidators = [self]
        config.searchAdsEnabled = true
        config.shouldUseRemotePublishSettings = false
        config.batchingEnabled = true
        config.batchSize = 5
        config.memoryReportingEnabled = true
        config.diskStorageEnabled = true
        //config.visitorServiceDelegate = self
        config.memoryReportingEnabled = true
        config.batterySaverEnabled = true
        config.remoteAPIEnabled = false
        logger = config.logger
        config.collectors = [
            MyDateCollector.self,
//            Collectors.Attribution,
            Collectors.AutoTracking,
                             Collectors.Lifecycle,
//                             Collectors.AppData,
                             Collectors.Connectivity,
//                             Collectors.Crash,
                             Collectors.Device,
//                             Collectors.Location,
                             Collectors.VisitorService,
            HostedDataLayer.self,
        ]
        
        config.hostedDataLayerKeys = ["hdl-test": "product_id"]
        config.hostedDataLayerTimeToLive = 1
        config.dispatchers = [Dispatchers.Collect,
//                              MyCustomDispatcher.self,
                              Dispatchers.TagManagement,
//                              Dispatchers.RemoteCommands
        ]
        
//        config.dispatchValidators = HostedDataLayer(config: T##TealiumConfig, delegate: T##ModuleDelegate?, diskStorage: T##TealiumDiskStorageProtocol?, completion: T##(ModuleResult) -> Void)
//        tealium?.dataLayerManager
//        config.geofenceUrl = "https://tags.tiqcdn.com/dle/tealiummobile/location/geofences.json"

        #if os(iOS)
//
//        let remoteCommand = TealiumRemoteCommand(commandId: "display",
//                                                 description: "test") { response in
//                                                    var response = response
//                                                    if TealiumHelper.shared.enableHelperLogs {
//                                                        print("*** TealiumHelper: Remote Command Executed: response:\(response)")
//                                                    }
//                                                    let dict = ["hello":"from helper"]
//                                                    // set some JSON response data to be passed back to the webview
//                                                    let myJson = try? JSONSerialization.data(withJSONObject: dict, options: [])
//                                                    response.data = myJson
//        }
//        config.addRemoteCommand(remoteCommand)
        #endif
//        config.diskStorageDirectory = .documents
//        config.loggerType = .custom(<#T##TealiumLoggerProtocol#>)
        tealium = Tealium(config: config) { [weak self] response in
            guard let self = self,
                let teal = self.tealium else {
                return
                
            }

//            self.track(title: "init", data: nil)
            let dataLayer = teal.dataLayer
            teal.consentManager?.userConsentStatus = .consented
            dataLayer.add(key: "myvarforever", value: 123456, expiry: .forever)

            // dataLayer.add(data: ["some_key1": "some_val1"])
            dataLayer.add(data: ["some_key1": "some_val1"], expiry: .session)

            dataLayer.add(data: ["some_key_forever":"some_val_forever"], expiry: .forever) // forever

            dataLayer.add(data: ["until": "restart"], expiry: .untilRestart)

            dataLayer.add(data: ["custom": "expire in 3 min"], expiry: .afterCustom((.minutes, 3)))

            dataLayer.delete(for: ["myvarforever"])

            dataLayer.add(data: ["hello": "world"], expiry: .untilRestart)

            dataLayer.add(key: "test", value: 123, expiry: .session)
            //dataLayer.add(key: "test", value: 123)

            dataLayer.delete(for: ["hello", "test"])

            dataLayer.add(key: "hello", value: "itsme", expiry: .afterCustom((.months, 1)))

//            print("Volatile Data: \(String(describing: sessionPersistence.dictionary))")
//
//            print("Persistent Data: \(String(describing: persitence.dictionary))")
//            print("Visitor ID: \(self.tealium?.visitorId ?? "not ready")")
//            print("Tealium Ready: \(self.tealium!.isReady)")
        }
        
//        print("Tealium Ready: \(self.tealium!.isReady)")
//        let dispatch = EventDispatch("hello-post-open")
//
//        tealium?.track(dispatch)
//        let dispatch = ViewDispatch("VIEW_NAME", dataLayer: ["key": "value"])
        #if os(iOS)
        guard let remoteCommands = tealium?.remoteCommands else {
            return
        }
        let remoteCommand = TealiumRemoteCommand(commandId: "display", description: "Test") { response in
            let payload = response.payload()
            guard let hello = payload["hello"] as? String,
                let key = payload["key"] as? String,
                let tealium = payload["tealium"] as? String else {
                print("Remote Command didnt work 👎 \(payload)")
                return
            }
            print("Remote Command data: hello = \(hello), key = \(key), tealium = \(tealium) 🎉🎊")
        }
        remoteCommands.add(remoteCommand)
        #endif
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
//        let dispatch = EventDispatch(title, dataLayer: data)
        let dispatch = ViewDispatch("hdl-test", dataLayer: ["product_id":"bcsd234"])
        tealium?.track(dispatch)
    }

    func trackView(title: String, data: [String: Any]?) {
//        let dispatch = ViewDispatch(title, dataLayer: data)
        let dispatch = ViewDispatch("hdl-test", dataLayer: ["product_id":"abc123"])
        tealium?.track(dispatch)

    }
    
    func joinTrace(_ traceID: String) {
        self.tealium?.joinTrace(id: traceID)
    }

    func leaveTrace() {
        self.tealium?.leaveTrace()
//        self.tealium?.flushQueue()
//        tealium?.dataLayer.
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
    var isReady: Bool
    
    var id = "MyCustomDispatcher"
    
    var config: TealiumConfig
    
    required init(config: TealiumConfig, delegate: ModuleDelegate, completion: ModuleCompletion?) {
        self.config = config
        self.isReady = true
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
