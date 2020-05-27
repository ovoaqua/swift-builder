//
//  TealiumConsentManager.swift
//  tealium-swift
//
//  Created by Craig Rouse on 3/29/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation

public class TealiumConsentManager {

    private weak var delegate: TealiumModuleDelegate?
    private var tealiumConfig: TealiumConfig?
    private var consentUserPreferences: TealiumConsentUserPreferences!
    private var consentPreferencesStorage: TealiumConsentPreferencesStorage?
    var consentLoggingEnabled = false
    weak var consentManagerModuleInstance: TealiumConsentManagerModule?
    var diskStorage: TealiumDiskStorageProtocol?

    /// Initialize consent manager￼.
    ///
    /// - Parameters:
    ///     - config: `TealiumConfig`￼
    ///     - delegate: `TealiumModuleDelegate?`￼
    ///     - diskStorage: `TealiumDiskStorageProtocol` instance to allow overriding for unit testing￼
    ///     - completion: Optional completion block, called when fully initialized
    public init(config: TealiumConfig,
                      delegate: TealiumModuleDelegate?,
                      diskStorage: TealiumDiskStorageProtocol,
                      _ completion: (() -> Void)?) {
        self.diskStorage = diskStorage
        consentPreferencesStorage = TealiumConsentPreferencesStorage(diskStorage: diskStorage)
        tealiumConfig = config
        consentLoggingEnabled = config.consentLoggingEnabled
        self.delegate = delegate
        // try to load config from persistent storage first
        if let preferences = getSavedPreferences() {
            consentUserPreferences = preferences
            // always need to update the consent cookie in TiQ, so this will trigger update_consent_cookie
            trackUserConsentPreferences(preferences: consentUserPreferences)
        } else {
            // not yet determined state.
            consentUserPreferences = TealiumConsentUserPreferences(consentStatus: .unknown, consentCategories: nil)
        }
        completion?()
    }

    /// Sets the module delegate￼.
    ///
    /// - Parameter delegate: `TealiumModuleDelegate`
    public func setModuleDelegate(delegate: TealiumModuleDelegate) {
        self.delegate = delegate
    }

    /// Sends a track call containing the consent settings if consent logging is enabled￼.
    ///
    /// - Parameter preferences: `TealiumConsentUserPreferences?`
    func trackUserConsentPreferences(preferences: TealiumConsentUserPreferences?) {
        if let preferences = preferences, var consentData = preferences.dictionary {
            
            let policy = tealiumConfig?.consentPolicyOverride ?? TealiumConsentPolicy.gdpr
            consentData[TealiumConsentConstants.policyKey] = policy.rawValue
            
            let totalCategories = TealiumConsentCategories.all().count
            if preferences.consentStatus == .consented {
                if let currentCategories = preferences.consentCategories?.count, currentCategories < totalCategories {
                    consentData[TealiumKey.event] = TealiumConsentConstants.consentPartialEventName
                } else {
                    consentData[TealiumKey.event] = TealiumConsentConstants.consentGrantedEventName
                }
            } else {
                consentData[TealiumKey.event] = TealiumConsentConstants.consentDeclinedEventName
            }

            // this track call must only be sent if "Log Consent Changes" is enabled and user has consented
            if consentLoggingEnabled {
                // call type must be set to override "link" or "view"
                consentData[TealiumKey.callType] = consentData[TealiumKey.event]
                delegate?.requestTrack(TealiumTrackRequest(data: consentData, completion: nil))
            }
            // in all cases, update the cookie data in TiQ/webview
            updateTIQCookie(consentData)
        }
    }

    /// Sends the track call to update TiQ cookie info. Ignored by Collect module.￼
    ///
    /// - Parameter consentData: `[String: Any]` containing the consent preferences
    func updateTIQCookie(_ consentData: [String: Any]) {
        var consentData = consentData
        // may change: currently, a separate call is required to TiQ to set the relevant cookies in the webview
        // collect module ignores this hit
        consentData[TealiumKey.event] = TealiumKey.updateConsentCookieEventName
        consentData[TealiumKey.callType] = TealiumKey.updateConsentCookieEventName
        delegate?.requestTrack(TealiumTrackRequest(data: consentData, completion: nil))
    }

    /// - Returns: `TealiumConsentUserPreferences?` from persistent storage
    func getSavedPreferences() -> TealiumConsentUserPreferences? {
        consentPreferencesStorage?.retrieveConsentPreferences()
    }

    /// Saves current consent preferences to persistent storage.
    func storeConsentUserPreferences() {
        guard let consentUserPrefs = getUserConsentPreferences() else {
            return
        }
        // store data
        consentPreferencesStorage?.storeConsentPreferences(consentUserPrefs)
    }

    /// Sets the current consent preferences￼.
    ///
    /// - Parameter prefs: `TealiumConsentUserPreferences`
    func setConsentUserPreferences(_ prefs: TealiumConsentUserPreferences) {
        consentUserPreferences = prefs
    }

    /// Used by the Consent Manager module to determine if tracking calls can be sent.
    ///
    /// - Returns: `TealiumConsentTrackAction` indicating whether tracking is allowed or forbidden
    public func getTrackingStatus() -> TealiumConsentTrackAction {
        if getUserConsentPreferences()?.consentStatus == .consented {
            return .trackingAllowed
        } else if getUserConsentPreferences()?.consentStatus == .notConsented {
            return .trackingForbidden
        }
        return .trackingQueued
    }
}

// MARK: Public API
public extension TealiumConsentManager {

    /// Sets consent status only. Will set the full list of consent categories if the status is `.consented`.￼
    ///
    /// - Parameter status: `TealiumConsentStatus?`
    func setUserConsentStatus(_ status: TealiumConsentStatus) {
        var categories = [TealiumConsentCategories]()
        if status == .consented {
            categories = TealiumConsentCategories.all()
        }
        setUserConsentStatusWithCategories(status: status, categories: categories)
    }

    /// Sets consent categories (implies `TealiumConsentStatus = .consented`.
    ///
    /// - Parameter status: `[TealiumConsentCategories]`
    func setUserConsentCategories(_ categories: [TealiumConsentCategories]) {
        setUserConsentStatusWithCategories(status: .consented, categories: categories)
    }

    /// Can set both Consent Status and Consent Categories in a single call￼.
    ///
    /// - Parameters:
    ///     - status: `TealiumConsentStatus?`￼
    ///     - categories: `[TealiumConsentCategories]?`
    private func setUserConsentStatusWithCategories(status: TealiumConsentStatus?, categories: [TealiumConsentCategories]?) {
        guard let _ = consentUserPreferences else {
            consentUserPreferences = TealiumConsentUserPreferences(consentStatus: status ?? .unknown, consentCategories: categories)
            trackUserConsentPreferences(preferences: consentUserPreferences)
            storeConsentUserPreferences()
            return
        }
        if let status = status {
            consentUserPreferences?.setConsentStatus(status)
        }
        if let categories = categories {
            consentUserPreferences?.setConsentCategories(categories)
        }
        storeConsentUserPreferences()
        trackUserConsentPreferences(preferences: consentUserPreferences)
        //consentStatusChanged(status)
    }

    /// Utility method to determine if consent categories have changed￼.
    ///
    /// - Parameters:
    ///     - lhs: `[TealiumConsentCategories]`￼
    ///     - rhs: `[TealiumConsentCategories]`
    func consentCategoriesEqual(_ lhs: [TealiumConsentCategories], _ rhs: [TealiumConsentCategories]) -> Bool {
        let lhs = lhs.sorted { $0.rawValue < $1.rawValue }
        let rhs = rhs.sorted { $0.rawValue < $1.rawValue }
        return lhs == rhs
    }

    /// - Returns: `TealiumConsentStatus`
    func getUserConsentStatus() -> TealiumConsentStatus {
        return consentUserPreferences?.consentStatus ?? TealiumConsentStatus.unknown
    }

    /// - Returns: `[TealiumConsentCategories]? `containing all current consent categories
    func getUserConsentCategories() -> [TealiumConsentCategories]? {
        return consentUserPreferences?.consentCategories
    }

    /// - Returns: `TealiumConsentUserPreferences?` containing all current consent preferences
    func getUserConsentPreferences() -> TealiumConsentUserPreferences? {
        return consentUserPreferences
    }

    /// Resets all consent preferences in memory and in persistent storage.
    func resetUserConsentPreferences() {
        consentPreferencesStorage?.clearStoredPreferences()
        consentUserPreferences?.resetConsentCategories()
        consentUserPreferences?.setConsentStatus(.unknown)
        trackUserConsentPreferences(preferences: consentUserPreferences)
    }
}
