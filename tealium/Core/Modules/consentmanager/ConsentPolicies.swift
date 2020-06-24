//
//  UserConsentPreferencesCCPA.swift
//  TealiumCore
//
//  Created by Craig Rouse on 08/06/2020.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

protocol ConsentPolicy {
    init (_ preferences: TealiumUserConsentPreferences)
    var shouldUpdateConsentCookie: Bool { get }
    var updateConsentCookieEventName: String { get }
    var consentPolicyStatusInfo: [String: Any]? { get }
    var preferences: TealiumUserConsentPreferences { get set }
    var trackAction: TealiumConsentTrackAction { get }
    var consentTrackingEventName: String { get }
    var shouldLogConsentStatus: Bool { get }
}

struct CCPAConsentPolicy: ConsentPolicy {
    
    init(_ preferences: TealiumUserConsentPreferences) {
        self.preferences = preferences
    }
    
    // Currently only supported by TiQ and no way to figure out which tags are in scope for consent logging
    var shouldLogConsentStatus = false
    
    var consentTrackingEventName: String {
        return self.currentStatus == .consented ? TealiumConsentConstants.consentGrantedEventName : TealiumConsentConstants.consentPartialEventName
    }
    
    var preferences: TealiumUserConsentPreferences
    
    var currentStatus: TealiumConsentStatus {
        preferences.consentStatus
    }
    
    var shouldUpdateConsentCookie: Bool = true
    
    var updateConsentCookieEventName = TealiumConsentConstants.ccpaCookieEventName
    
    var trackAction: TealiumConsentTrackAction {
        return .trackingAllowed
    }
    
    var consentPolicyStatusInfo: [String: Any]? {
        let doNotSell = currentStatus == .notConsented ? true : false
        return [TealiumConsentConstants.doNotSellKey: doNotSell,
                TealiumConsentConstants.policyKey: TealiumConsentPolicy.ccpa.rawValue]
    }
}


struct GDPRConsentPolicy: ConsentPolicy {
    
    init(_ preferences: TealiumUserConsentPreferences) {
        self.preferences = preferences
    }
    
    var shouldLogConsentStatus = true
    
    var consentTrackingEventName: String {
        if preferences.consentStatus == .notConsented {
            return TealiumConsentConstants.consentDeclinedEventName
        }
        if let currentCategories = preferences.consentCategories?.count, currentCategories < TealiumConsentCategories.allCategories.count {
            return TealiumConsentConstants.consentPartialEventName
        } else {
          return TealiumConsentConstants.consentGrantedEventName
        }
    }
    
    var preferences: TealiumUserConsentPreferences
    
    var shouldUpdateConsentCookie = true
    
    var updateConsentCookieEventName = TealiumConsentConstants.gdprConsentCookieEventName
    
    var currentStatus: TealiumConsentStatus {
        preferences.consentStatus
    }
    
    var currentCategories: [TealiumConsentCategories]? {
        preferences.consentCategories
    }

    var consentPolicyStatusInfo: [String: Any]? {
        var params = preferences.dictionary ?? [String: Any]()
        params[TealiumConsentConstants.policyKey] = TealiumConsentPolicy.gdpr.rawValue
        return params
    }
    
    var trackAction: TealiumConsentTrackAction {
        get {
            switch currentStatus {
            case .consented:
                return .trackingAllowed
            case .notConsented:
                return .trackingForbidden
            case .unknown:
                return .trackingQueued
            }
        }
    }
}

