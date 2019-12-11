//
//  TealiumPublishSettingsRetriever.swift
//  TealiumCore
//
//  Created by Craig Rouse on 02/12/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

extension Date {
    var httpIfModifiedHeader: String {
        get {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "E, dd MMM YYYY HH:mm:ss"
            return "\(dateFormatter.string(from: self)) GMT"
        }
    }
    func addMinutes(_ mins: Double?) -> Date? {
        guard let mins = mins else {
            return nil
        }
        let seconds = mins * 60
        guard let timeInterval = TimeInterval(exactly: seconds) else {
            return nil
        }
        return self.addingTimeInterval(timeInterval)
    }
}

public enum HttpStatusCodes: Int {
    case notModified = 304
    case ok = 200
}

protocol TealiumPublishSettingsDelegate: class {
    
    func didUpdate(_ publishSettings: RemotePublishSettings)
}

class TealiumPublishSettingsRetriever {
    
    // todo: head request
    
    var diskStorage: TealiumDiskStorageProtocol
    var urlSession: URLSessionProtocol?
    weak var delegate: TealiumPublishSettingsDelegate?
    var cachedSettings: RemotePublishSettings?
    var config: TealiumConfig
    var hasFetched = false
    
    init(config: TealiumConfig,
         diskStorage: TealiumDiskStorageProtocol? = nil,
         urlSession: URLSessionProtocol? = URLSession(configuration: .ephemeral),
         delegate: TealiumPublishSettingsDelegate) {
        self.config = config
        self.diskStorage = diskStorage ?? TealiumDiskStorage(config: config, forModule: "publishsettings", isCritical: true)
        self.cachedSettings = getCachedSettings()
        self.urlSession = urlSession
        self.delegate = delegate
        self.refresh()
    }
    
    func refresh() {
        // always request on launch
        if !hasFetched || self.cachedSettings == nil {
            self.getAndSave(baseUrl: "https://tags.tiqcdn.com", account: config.account, profile: config.profile, env: config.environment)
            return
        }
        
        guard let date = self.cachedSettings?.lastFetch.addMinutes(self.cachedSettings?.minutesBetweenRefresh), Date() > date else {
            return
        }
        self.getAndSave(baseUrl: "https://tags.tiqcdn.com", account: config.account, profile: config.profile, env: config.environment)
        
    }
    
    func getCachedSettings() -> RemotePublishSettings? {
        let settings = self.diskStorage.retrieve(as: RemotePublishSettings.self)
        return settings
    }
    
    func getAndSave(baseUrl: String,
                     account: String,
                     profile: String,
                     env: String) {
        hasFetched = true
        let url = URL(string: "\(baseUrl)/utag/\(account)/\(profile)/\(env)")

        guard let mobileHTML = url?.appendingPathComponent("mobile.html") else {
            return
        }
        
        self.getRemoteSettings(url: mobileHTML,
                               lastFetch: self.cachedSettings?.lastFetch) { settings in
            if let settings = settings {
                self.cachedSettings = settings
                self.diskStorage.save(settings, completion: nil)
                self.delegate?.didUpdate(settings)
            }
        }

    }
    
    func getRemoteSettings(url: URL,
                           lastFetch: Date?,
                           completion: @escaping (RemotePublishSettings?)-> Void) {
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let lastFetch = lastFetch {
            request.setValue(lastFetch.httpIfModifiedHeader, forHTTPHeaderField: "If-Modified-Since")
            request.setValue(nil, forHTTPHeaderField: "If-None-Match")
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        }
        
        self.urlSession?.tealiumDataTask(with: request) { data, response, error in
            
            guard let response = response as? HTTPURLResponse else {
                completion(nil)
                return
            }
            
            switch HttpStatusCodes(rawValue: response.statusCode) {
                case .ok:
                guard let publishSettings = self.getPublishSettings(from: data!) else {
                    completion(nil)
                    return
                }
                
                completion(publishSettings)
                default:
                    completion(nil)
                return
            }
        }.resume()
    }
    
    
    func getPublishSettings(from data: Data) -> RemotePublishSettings? {
        guard let dataString = String(data: data, encoding: .utf8) else {
            return nil
        }

        let startScript = dataString.range(of: "var mps = ")
        let endScript = dataString.range(of: "</script>")

        let string = dataString[..<endScript!.lowerBound]
        let newSubString = string[startScript!.upperBound...]

        guard let data = newSubString.data(using: .utf8) else {
            return nil
        }
        
        return try? JSONDecoder().decode(RemotePublishSettings.self, from: data)

    }
}
