//
//  HostedDataLayer.swift
//  TealiumCore
//
//  Created by Craig Rouse on 13/07/2020.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

protocol HostedDataLayerProtocol: DispatchValidator, Collector {
    var cache: [HostedDataLayerCacheItem] { get set }
    func getURL(for dispatch: TealiumTrackRequest) -> URL?
    func requestData(for url: URL, completion: ((Result<[String: Any], Error>) -> Void))
}

struct HostedDataLayerCacheItem {
    var id: String
    var data: [String: Any]
}

class HostedDataLayer: HostedDataLayerProtocol {
    var cache: [HostedDataLayerCacheItem] = []

    var id = "HostedDataLayer"
    var config: TealiumConfig

    required init(config: TealiumConfig, delegate: ModuleDelegate?, diskStorage: TealiumDiskStorageProtocol?, completion: (ModuleResult) -> Void) {
        self.config = config
    }

    func shouldQueue(request: TealiumRequest) -> (Bool, [String: Any]?) {
        return (false, nil)
    }

    func shouldDrop(request: TealiumRequest) -> Bool {
        return false
    }

    func shouldPurge(request: TealiumRequest) -> Bool {
        return false
    }

    var data: [String: Any]?

    func getURL(for dispatch: TealiumTrackRequest) -> URL? {
        return nil
    }

    func requestData(for url: URL,
                     completion: ((Result<[String: Any], Error>) -> Void)) {

    }

}
