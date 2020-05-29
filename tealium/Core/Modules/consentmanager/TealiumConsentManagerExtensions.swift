//
//  TealiumConsentManagerExtensions.swift
//  tealium-swift
//
//  Created by Craig Rouse on 20/03/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

// public interface for consent manager
public extension Tealium {
    
    /// - Returns: `TealiumConsentManager` instance
    var consentManager: TealiumConsentManager? {
        let module = zz_internal_modulesManager?.collectors.filter {
            $0 is TealiumConsentManagerModule
        }.first
        return (module as? TealiumConsentManagerModule)?.consentManager
    }

}

public extension TealiumConfig {
    
    /// Enables the `TealiumConsentManager` which is disabled by default
    var enableConsentManager: Bool {
        get {
            optionalData[TealiumConsentConstants.enableConsentManager] as? Bool ?? false
        }
        set {
            optionalData[TealiumConsentConstants.enableConsentManager] = newValue
        }
    }

    /// Determines whether consent logging events should be sent to Tealium UDH￼.
    ///
    /// - Parameter enabled: `Bool` `true` if enabled
    @available(*, deprecated, message: "Please switch to config.consentLoggingEnabled")
    func setConsentLoggingEnabled(_ enabled: Bool) {
        consentLoggingEnabled = enabled
    }

    /// Checks if consent logging is currently enabled.
    ///
    /// - Returns: `Bool` true if enabled
    @available(*, deprecated, message: "Please switch to config.consentLoggingEnabled")
    func isConsentLoggingEnabled() -> Bool {
        consentLoggingEnabled
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
    func setOverrideConsentPolicy(_ policy: TealiumConsentPolicy) {
        consentPolicyOverride = policy
    }

    /// Retrieves the current overridden consent policy.
    ///
    /// - Returns: `String?` containing the consent policy
    @available(*, deprecated, message: "Please switch to config.consentPolicyOverride")
    func getOverrideConsentPolicy() -> TealiumConsentPolicy? {
        consentPolicyOverride
    }

    /// Overrides the consent policy (defaults to GDPR)￼. e.g. CCPA
    var consentPolicyOverride: TealiumConsentPolicy? {
        get {
            optionalData[TealiumConsentConstants.policyKey] as? TealiumConsentPolicy
        }

        set {
            optionalData[TealiumConsentConstants.policyKey] = newValue
        }
    }

}
