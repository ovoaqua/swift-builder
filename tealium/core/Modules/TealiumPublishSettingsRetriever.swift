//
//  TealiumPublishSettingsRetriever.swift
//  TealiumCore
//
//  Created by Craig Rouse on 02/12/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

class TealiumPublishSettingsRetriever {
    
    // todo: head request
    
    var diskStorage: TealiumDiskStorageProtocol
    
    init(config: TealiumConfig,
         diskStorage: TealiumDiskStorageProtocol? = nil) {
        self.diskStorage = diskStorage ?? TealiumDiskStorage(config: config, forModule: "publishsettings", isCritical: true)
        self.getUtagFile(baseUrl: "https://tags.tiqcdn.com", account: config.account, profile: config.profile, env: config.environment)
    }
    
    func getCachedSettings() -> RemotePublishSettings? {
        let settings = self.diskStorage.retrieve(as: RemotePublishSettings.self)
        return settings
    }
    
    func getUtagFile(baseUrl: String,
                     account: String,
                     profile: String,
                     env: String) {

        let url = URL(string: "\(baseUrl)/utag/\(account)/\(profile)/\(env)")
//        guard let utagURL = url?.appendingPathComponent("utag.js") else {
//            return
//        }

        guard let mobileHTML = url?.appendingPathComponent("mobile.html") else {
            return
        }
////         data, urlresponse, error in...
//        URLSession.shared.dataTask(with: utagURL) { abc, def, ghi in
////            print("hello")
////            try? Disk.save(abc!, to: .caches, as: "tealiummobile.demo/tagmanagement/utag.js")
////            print("\(abc)\(def)\(ghi)")
//        }.resume()

        URLSession.shared.dataTask(with: mobileHTML) { data, def, ghi in
//            print("hello")
            try? Disk.save(data!, to: .caches, as: "tealiummobile.demo/tagmanagement/mobile.html")
            if let publishSettings = self.getPublishSettings(from: data!) {
//                try? Disk.save(publishSettings, to: .caches, as: "tealiummobile.demo/core/publishsetttings")
                self.diskStorage.save(publishSettings, completion: nil)
            }
//            print("\(abc)\(def)\(ghi)")
        }.resume()

    }
    
    func getPublishSettings(from data: Data) -> RemotePublishSettings? {
        guard let dataString = String(data: data, encoding: .utf8) else {
            return nil
        }

        let endScript = dataString.range(of: "</script>")
        let startScript = dataString.range(of: "var mps = ")

        let string = dataString[..<endScript!.lowerBound]
        let newSubString = string[startScript!.upperBound...]

        guard let data = newSubString.data(using: .utf8) else {
            return nil
        }
        
        
        
        return try? JSONDecoder().decode(RemotePublishSettings.self, from: data)

//        return try! JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]

    }
}
