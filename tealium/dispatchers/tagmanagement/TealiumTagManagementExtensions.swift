//
//  TealiumTagManagementExtensions.swift
//  tealium-swift
//
//  Created by Craig Rouse on 07/03/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//
#if os(iOS)
import Foundation
import UIKit
import WebKit
#if tagmanagement
import TealiumCore
#endif

// MARK: EXTENSIONS

public extension TealiumConfig {
    
    /// Adds optional delegates to the WebView instance.
    var webViewDelegates: [WKNavigationDelegate]? {
        get {
            options[TealiumTagManagementConfigKey.delegate] as? [WKNavigationDelegate]
        }

        set {
            options[TealiumTagManagementConfigKey.delegate] = newValue
        }
    }

    /// Optional override for the tag management webview URL.
    var tagManagementOverrideURL: String? {
        get {
            options[TealiumTagManagementConfigKey.overrideURL] as? String
        }

        set {
            options[TealiumTagManagementConfigKey.overrideURL] = newValue
        }
    }

    /// Gets the URL to be loaded by the webview (mobile.html).
    ///
    /// - Returns: `URL` representing either the custom URL provided in the `TealiumConfig` object, or the default Tealium mCDN URL
    var webviewURL: URL? {
        if let overrideWebviewURL = tagManagementOverrideURL {
            return URL(string: overrideWebviewURL)
        } else {
            return URL(string: "\(TealiumTagManagementKey.defaultUrlStringPrefix)/\(self.account)/\(self.profile)/\(self.environment)/mobile.html")
        }
    }

    /// Sets a root view for `WKWebView` to be attached to. Only required for complex view hierarchies.
    var rootView: UIView? {
        get {
            options[TealiumTagManagementConfigKey.uiview] as? UIView
        }

        set {
            options[TealiumTagManagementConfigKey.uiview] = newValue
        }
    }

    var shouldAddCookieObserver: Bool {
        get {
            return options[TealiumTagManagementConfigKey.cookieObserver] as? Bool ?? true
        }

        set {
            options[TealiumTagManagementConfigKey.cookieObserver] = newValue
        }
    }

}

#if TEST
#else
extension Tealium {

    /// - Returns: `TealiumTagManagementProtocol` (`WKWebView` for iOS11+)
    var tagManagement: TealiumTagManagementProtocol? {
            let module = zz_internal_modulesManager?.modules.filter {
                $0 is TealiumTagManagementModule
            }.first
        
            return (module as? TealiumTagManagementModule)?.tagManagement
    }
    
    /// Sets a new root view for `WKWebView` to be attached to. Only required for complex view hierarchies.
    ///￼
    /// - Parameter view: `UIView` instance for `WKWebView` to be attached to
    public func updateRootView(_ view: UIView) {
        self.tagManagement?.setRootView(view, completion: nil)
    }
}
#endif
#endif
