//
//  TealiumHelper.swift
//
//  Created by Christina S on 7/6/20.
//  Copyright © 2019 Tealium. All rights reserved.
//

import Foundation
import TealiumSwift

enum TealiumConfiguration {
    static let account = "tealiummobile"
    static let profile = "demo"
    static let environment = "dev"
    static let dataSourceKey = "abc123"
}

let enableLogs = true

public enum WebViewExampleType: Equatable {
    case noUtag // example webview without utag
    case withUtag // example webview with mobile.html/utag.js
}

class TealiumHelper {

    static let shared = TealiumHelper()

    let config = TealiumConfig(account: TealiumConfiguration.account,
                               profile: TealiumConfiguration.profile,
                               environment: TealiumConfiguration.environment,
                               dataSource: TealiumConfiguration.dataSourceKey)

    var tealium: Tealium?
    
    // set this to change the example that loads - JSInterfaceExample
    private var exampleType: WebViewExampleType = .withUtag

    // MARK: Tealium Initilization
    private init() {
        // Optional Config Settings
        if enableLogs { config.logLevel = .debug }

        config.memoryReportingEnabled = true
        config.diskStorageEnabled = true
        config.visitorServiceDelegate = self
        config.consentLoggingEnabled = true
        config.consentPolicy = .ccpa
        
        // Add collectors
        #if os(iOS)
        config.collectors = [Collectors.Attribution, Collectors.VisitorService]
        
        // Add dispatchers
        config.dispatchers = [Dispatchers.TagManagement, Dispatchers.RemoteCommands]
        
        // To enable batching:
        // config.batchSize = 5
        // config.batchingEnabled = true
        
        // Location
        // config.geofenceUrl = "http://tags.tiqcdn.com/dle/tealiummobile/location/geofences.json"
        
        // Remote Commands
        let remoteCommand = TealiumRemoteCommand(commandId: "hello", description: "world") { response in
            let payload = response.payload()
            // Do something w/remote command payload
            if enableLogs {
                print(payload)
            }
        }
        config.addRemoteCommand(remoteCommand)
        #endif
        
        tealium = Tealium(config: config) { response in
            // Optional post init processing
            self.tealium?.dataLayer.add(data: ["somekey": "someval"], expiry: .afterCustom((.months, 1)))
            self.tealium?.dataLayer.add(key: "someotherkey", value: "someotherval", expiry: .forever)
        }

    }

    public func start() {
        _ = TealiumHelper.shared
    }

    class func trackView(title: String, dataLayer: [String: Any]?) {
        let dispatch = ViewDispatch(title, dataLayer: dataLayer)
        TealiumHelper.shared.tealium?.track(dispatch)
    }

    class func trackEvent(title: String, dataLayer: [String: Any]?) {
        let dispatch = EventDispatch(title, dataLayer: dataLayer)
        TealiumHelper.shared.tealium?.track(dispatch)
    }
    
    class func joinTrace(_ traceID: String) {
        TealiumHelper.shared.tealium?.joinTrace(id: traceID)
        TealiumHelper.trackEvent(title: "trace_started", dataLayer: nil)
    }

    class func leaveTrace() {
        TealiumHelper.shared.tealium?.leaveTrace()
    }
}

// MARK: Visitor Service Module Delegate
extension TealiumHelper: VisitorServiceDelegate {
    func didUpdate(visitorProfile: TealiumVisitorProfile) {
        if let json = try? JSONEncoder().encode(visitorProfile),
            let string = String(data: json, encoding: .utf8) {
            if enableLogs {
                print(string)
            }
        }
    }
}
