//
//  TealiumConsentManagerConfigExtensions.swift
//  tealium-swift
//
//  Created by Craig Rouse on 20/03/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if consentmanager
import TealiumCore
#endif

public extension TealiumConfig {

    /// Determines whether consent logging events should be sent to Tealium UDH￼.
    ///
    /// - Parameter enabled: `Bool` `true` if enabled
    @available(*, deprecated, message: "Please switch to config.consentLoggingEnabled")
    func setConsentLoggingEnabled(_ enabled: Bool) {
        optionalData[TealiumConsentConstants.consentLoggingEnabled] = enabled
    }

    /// Checks if consent logging is currently enabled.
    ///
    /// - Returns: `Bool` true if enabled
    @available(*, deprecated, message: "Please switch to config.consentLoggingEnabled")
    func isConsentLoggingEnabled() -> Bool {
        if let enabled = optionalData[TealiumConsentConstants.consentLoggingEnabled] as? Bool {
            return enabled
        }
        return false
    }

    /// Determines whether consent logging events should be sent to Tealium UDH￼.
    var consentLoggingEnabled: Bool {
        get {
            optionalData[TealiumConsentConstants.consentLoggingEnabled] as? Bool ?? false
        }

        set {
            optionalData[TealiumConsentConstants.consentLoggingEnabled] = newValue
        }
    }

    /// Overrides the consent policy (default GDPR)￼.
    ///
    /// - Parameter policy: `String` containing the policy (e.g. "CCPA)
    @available(*, deprecated, message: "Please switch to config.consentPolicyOverride")
    func setOverrideConsentPolicy(_ policy: String) {
        optionalData[TealiumConsentConstants.policyKey] = policy
    }

    /// Retrieves the current overridden consent policy.
    ///
    /// - Returns: `String?` containing the consent policy
    @available(*, deprecated, message: "Please switch to config.consentPolicyOverride")
    func getOverrideConsentPolicy() -> String? {
        return optionalData[TealiumConsentConstants.policyKey] as? String
    }

    /// Overrides the consent policy (defaults to GDPR)￼. e.g. CCPA
    var consentPolicyOverride: String? {
        get {
            optionalData[TealiumConsentConstants.policyKey] as? String
        }

        set {
            optionalData[TealiumConsentConstants.policyKey] = newValue
        }
    }

    /// Sets the initial consent status to be used before the user has selected an option￼.
    ///
    /// - Parameter status: `TealiumConsentStatus`
    @available(*, deprecated, message: "Please switch to config.initialUserConsentStatus")
    func setInitialUserConsentStatus(_ status: TealiumConsentStatus) {
        optionalData[TealiumConsentConstants.consentStatus] = status
    }

    /// Gets the initial consent status to be used before the user has selected an option.
    ///
    /// - Returns: `TealiumConsentStatus?`
    @available(*, deprecated, message: "Please switch to config.initialUserConsentStatus")
    func getInitialUserConsentStatus() -> TealiumConsentStatus? {
        if let status = optionalData[TealiumConsentConstants.consentStatus] as? TealiumConsentStatus {
            return status
        }
        return nil
    }

    /// Initial consent status to be used before the user has selected an option￼.
    var initialUserConsentStatus: TealiumConsentStatus? {
        get {
            optionalData[TealiumConsentConstants.consentStatus] as? TealiumConsentStatus
        }

        set {
            optionalData[TealiumConsentConstants.consentStatus] = newValue
        }
    }

    /// Sets the initial consent categories to be used before the user has selected an option￼.
    ///
    /// - Parameter categories: `[TealiumConsentCategories]`
    @available(*, deprecated, message: "Please switch to config.initialUserConsentCategories")
    func setInitialUserConsentCategories(_ categories: [TealiumConsentCategories]) {
        optionalData[TealiumConsentConstants.consentCategoriesKey] = categories
    }

    /// Gets the initial consent status to be used before the user has selected an option.
    /// 
    /// - Returns: `[TealiumConsentCategories]?`
    @available(*, deprecated, message: "Please switch to config.initialUserConsentCategories")
    func getInitialUserConsentCategories() -> [TealiumConsentCategories]? {
        if let categories = optionalData[TealiumConsentConstants.consentCategoriesKey] as? [TealiumConsentCategories] {
            return categories
        }
        return nil
    }

    /// Initial consent categories to be used before the user has selected an option￼.
    var initialUserConsentCategories: [TealiumConsentCategories]? {
        get {
            optionalData[TealiumConsentConstants.consentCategoriesKey] as? [TealiumConsentCategories]
        }

        set {
            optionalData[TealiumConsentConstants.consentCategoriesKey] = newValue
        }
    }
}
