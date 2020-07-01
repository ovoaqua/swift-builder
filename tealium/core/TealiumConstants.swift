//
//  TealiumConstants.swift
//  tealium-swift
//
//  Created by Jason Koo on 9/1/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//
#if os(iOS)
import UIKit
// MARK: VALUES
#endif

public enum TealiumValue {
    public static let libraryName = "swift"
    public static let libraryVersion = "2.0.0"
    // This is the current limit for performance reasons. May be increased in future
    public static let maxEventBatchSize = 10
    public static let defaultMinimumDiskSpace: Int32 = 20_000_000
    public static let tiqBaseURL = "https://tags.tiqcdn.com/utag/"
    public static let tiqURLSuffix = "mobile.html"
    public static let defaultBatchExpirationDays = 7
    public static let defaultMaxQueueSize = 40
    public static let optionalCollectors = [TealiumOptionalCollectors.attribution,
                                            // TealiumOptionalCollectors.autotracking,
                                            TealiumOptionalCollectors.crash,
                                            TealiumOptionalCollectors.lifecycle,
                                            TealiumOptionalCollectors.location,
                                            TealiumOptionalCollectors.visitorservice]
    public static let knownDispatchers = [TealiumKnownDispatchers.collect,
                                          TealiumKnownDispatchers.tagmanagement,
                                          TealiumKnownDispatchers.remotecommands]
}

public enum TealiumOptionalCollectors {
    #if COCOAPODS
    public static let attribution = "TealiumSwift.TealiumAttributionModule"
    public static let autotracking = "TealiumSwift.TealiumAutotrackingModule"
    public static let crash = "TealiumSwift.TealiumCrashModule"
    public static let lifecycle = "TealiumSwift.TealiumLifecycleModule"
    public static let location = "TealiumSwift.TealiumLocationModule"
    public static let visitorservice = "TealiumSwift.TealiumVisitorServiceModule"
    #else
    public static let attribution = "TealiumAttribution.TealiumAttributionModule"
    public static let autotracking = "TealiumAutotracking.TealiumAutotrackingModule"
    public static let crash = "TealiumCrash.TealiumCrashModule"
    public static let lifecycle = "TealiumLifecycle.TealiumLifecycleModule"
    public static let location = "TealiumLocation.TealiumLocationModule"
    public static let visitorservice = "TealiumVisitorService.TealiumVisitorServiceModule"
    #endif
}

public enum TealiumKnownDispatchers {
    #if COCOAPODS
    public static let collect = "TealiumSwift.TealiumCollectModule"
    public static let tagmanagement = "TealiumSwift.TealiumTagManagementModule"
    public static let remotecommands = "TealiumSwift.TealiumRemoteCommandsModule"
    #else
    public static let collect = "TealiumCollect.TealiumCollectModule"
    public static let tagmanagement = "TealiumTagManagement.TealiumTagManagementModule"
    public static let remotecommands = "TealiumRemoteCommands.TealiumRemoteCommandsModule"
    #endif
}

public enum TealiumModuleNames {
    public static let autotracking = "AutoTracking"
    public static let appdata = "AppData"
    public static let attribution = "Attribution"
    public static let collect = "Collect"
    public static let connectivity = "Connectivity"
    public static let consentmanager = "ConsentManager"
    public static let crash = "Crash"
    public static let devicedata = "DeviceData"
    public static let lifecycle = "Lifecycle"
    public static let location = "Location"
    public static let remotecommands = "RemoteCommands"
    public static let tagmanagement = "TagManagement"
    public static let visitorservice = "VisitorService"
}

public enum TealiumKey {
    public static let account = "tealium_account"
    public static let profile = "tealium_profile"
    public static let environment = "tealium_environment"
    public static let event = "tealium_event"
    public static let callType = "call_type"
    public static let screenTitle = "screen_title"
    public static let eventType = "tealium_event_type"
    public static let libraryName = "tealium_library_name"
    public static let libraryVersion = "tealium_library_version"
    public static let queueReason = "queue_reason"
    public static let wasQueued = "was_queued"
    public static let dispatchService = "dispatch_service"
    public static let updateConsentCookieEventNames = ["update_consent_cookie", "set_dns_state"]
    public static let jsNotificationName = "com.tealium.tagmanagement.jscommand"
    public static let tagmanagementNotification = "com.tealium.tagmanagement.urlrequest"
    public static let jsCommand = "js"
    public static let traceId = "cp.trace_id"
    public static let killVisitorSession = "kill_visitor_session"
    // used for remote commands
    public static let tealiumURLScheme = "tealium"
    public static let dataSource = "tealium_datasource"
    public static let sessionId = "tealium_session_id"
    public static let visitorId = "tealium_visitor_id"
    public static let random = "tealium_random"
    public static let uuid = "app_uuid"
    public static let requestUUID = "request_uuid"
    public static let simpleModel = "model_name" // e.g. iPhone 5s // OLD: device
    public static let device = "device" // == model_name
    public static let deviceType = "device_type"
    public static let fullModel = "model_variant" // e.g. CDMA, GSM
    public static let architectureLegacy = "cpu_architecture"
    public static let architecture = "device_architecture"
    public static let cpuTypeLegacy = "cpu_type"
    public static let cpuType = "device_cputype"
    public static let languageLegacy = "user_locale"
    public static let language = "device_language"
    public static let osName = "os_name"
    public static let platform = "platform"
    public static let resolution = "device_resolution"
    public static let minimumFreeDiskSpace = "min_free_disk_space"
    public static let diskStorageEnabled = "disk_storage"
    public static let logLevelConfig = "com.tealium.logger.loglevel"
    public static let timestampUnix = "timestamp_unix"
    public static let timestampUnixMilliseconds = "timestamp_unix_milliseconds"
    public static let prod = "prod"
    public static let dev = "dev"
    // swiftlint:disable identifier_name
    public static let qa = "qa"
    // swiftlint:enable identifier_name
    public static let errorHeaderKey = "X-Error"
    public static let diskStorageDirectory = "disk_storage_directory"
    public static let remoteAPICallType = "remote_api"
    public static let publishSettings = "remote_publish_settings"
    public static let publishSettingsURL = "publish_settings_url"
    public static let publishSettingsProfile = "publish_settings_profile"
    public static let enabledModules = "enabled_modules"
    public static let libraryEnabled = "library_is_enabled"
    public static let batterySaver = "battery_saver"
    public static let queueSizeKey = "queue_size"
    // number of events in a batch, max 10
    public static let batchSizeKey = "batch_size"
    // max stored events (e.g. if offline) to limit disk space consumed
    public static let eventLimit = "event_limit"
    public static let batchingEnabled = "batching_enabled"
    public static let batchExpirationDaysKey = "batch_expiration_days"
    public static let wifiOnlyKey = "wifi_only_sending"
    public static let minutesBetweenRefresh = "minutes_between_refresh"
    public static let collectModuleName = "collect"
    public static let tagManagementModuleName = "tagmanagement"
    public static let loggerType = "logger_type"
    public static let logLevel = "log_level"
    public static let logger = "com.tealium.logger"
    public static let shouldCollectTealiumData = "should_collect_tealium_data"
    public static let dispatchValidators = "dispatch_validators"
    public static let dispatchListeners = "dispatch_listeners"
    public static let collectors = "collectors"
    public static let dispatchers = "dispatchers"
}

public enum TealiumTrackType {
    case view           // Whenever content is displayed to the user.
    case event

    var description: String {
        switch self {
        case .view:
            return "view"
        case .event:
            return "event"
        }
    }

}

public typealias TealiumCompletion = ((_ successful: Bool, _ info: [String: Any]?, _ error: Error?) -> Void)

public enum TealiumConstants {
    static let libraryVersion = "2.0.0"
    static let defaultBatchSize = 10
    static let defaultLoggerType: TealiumLoggerType = .os
    static let defaultMinimumDiskSpace: Int32 = 20_000_000
    static let connectionRestoredReason = "Connection Restored"
}
