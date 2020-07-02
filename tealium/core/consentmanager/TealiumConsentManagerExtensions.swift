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
        let module = zz_internal_modulesManager?.collectors.first {
            $0 is ConsentManagerModule
        }
        return (module as? ConsentManagerModule)?.consentManager
    }

}

public extension TealiumConfig {

    /// Determines whether consent logging events should be sent to Tealium UDH￼.
    var consentLoggingEnabled: Bool {
        get {
            options[TealiumConsentConstants.consentLoggingEnabled] as? Bool ?? false
        }

        set {
            options[TealiumConsentConstants.consentLoggingEnabled] = newValue
        }
    }

    /// Sets the consent policy (defaults to GDPR)￼. e.g. CCPA
    var consentPolicy: TealiumConsentPolicy? {
        get {
            options[TealiumConsentConstants.policyKey] as? TealiumConsentPolicy
        }

        set {
            options[TealiumConsentConstants.policyKey] = newValue
        }
    }

}
