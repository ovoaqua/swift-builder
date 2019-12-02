//
//  TealiumPublishSettings.swift
//  TealiumCore
//
//  Created by Craig Rouse on 02/12/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

struct RemotePublishSettings: Codable {
    /* ALL STRINGS
    battery_saver: true/false
    dispatch_expiration: -1
    enable_collect: true/false
    enable_tag_management: true/false
    event_batch_size: 1
    minutes_between_refresh: 15.0
    offline_dispatch_limit: 100,
    override_log,
    wifi_only_sending: false
    _is_enabled: true
    **/

    var batterySaver: Bool
    var dispatchExpiration: Int
    var collectEnabled: Bool
    var tagManagementEnabled: Bool
    var batchSize: Int
    var minutesBetweenRefresh: Double
    var dispatchQueueLimit: Int
    var overrideLog: TealiumLogLevel
    var wifiOnlySending: Bool
    var isEnabled: Bool
    
    enum CodingKeys: String, CodingKey {
        case battery_saver
        case dispatch_expiration
        case enable_collect
        case enable_tag_management
        case event_batch_size
        case minutes_between_refresh
        case offline_dispatch_limit
        case override_log
        case wifi_only_sending
        case _is_enabled
    }
    
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.batterySaver = try values.decode(String.self, forKey: .battery_saver) == "true" ? true : false
        self.dispatchExpiration = Int(try values.decode(String.self, forKey: .dispatch_expiration), radix: 10) ?? -1
        self.collectEnabled = try values.decode(String.self, forKey: .enable_collect) == "true" ? true : false
        self.tagManagementEnabled = try values.decode(String.self, forKey: .enable_tag_management) == "true" ? true : false
        self.batchSize = Int(try values.decode(String.self, forKey: .event_batch_size), radix: 10) ?? 1
        self.minutesBetweenRefresh = Double(try values.decode(String.self, forKey: .minutes_between_refresh)) ?? 15.0
        self.dispatchQueueLimit = Int(try values.decode(String.self, forKey: .offline_dispatch_limit), radix: 10) ?? 100
        let logLevel = try values.decode(String.self, forKey: .offline_dispatch_limit)
        
        switch logLevel {
        case "dev":
            self.overrideLog = .verbose
        case "qa":
            self.overrideLog = .warnings
        case "prod":
            self.overrideLog = .errors
        default:
            self.overrideLog = .none
        }
        
        self.wifiOnlySending = try values.decode(String.self, forKey: .wifi_only_sending) == "true" ? true : false
        self.isEnabled = try values.decode(String.self, forKey: ._is_enabled) == "true" ? true : false
        
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(batterySaver, forKey: .battery_saver)
        try container.encode(dispatchExpiration, forKey: .dispatch_expiration)
        try container.encode(collectEnabled, forKey: .enable_collect)
        try container.encode(tagManagementEnabled, forKey: .enable_tag_management)
        try container.encode(batchSize, forKey: .event_batch_size)
        try container.encode(minutesBetweenRefresh, forKey: .minutes_between_refresh)
        try container.encode(dispatchQueueLimit, forKey: .offline_dispatch_limit)
        // TODO: this is different to the original value, so won't encode
        try container.encode(overrideLog.description, forKey: .override_log)
        try container.encode(wifiOnlySending, forKey: .wifi_only_sending)
        try container.encode(isEnabled, forKey: ._is_enabled)
    }
    
}
