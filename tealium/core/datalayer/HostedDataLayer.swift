//
//  HostedDataLayer.swift
//  TealiumCore
//
//  Created by Craig Rouse on 13/07/2020.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

protocol HostedDataLayerProtocol: DispatchValidator, Collector {
    var cache: [HostedDataLayerCacheItem]? { get set }
    var retriever: HostedDataLayerRetrieverProtocol { get set }
    func getURL(for dispatch: TealiumTrackRequest) -> URL?
}

public class HostedDataLayer: HostedDataLayerProtocol {
    var retriever: HostedDataLayerRetrieverProtocol = HostedDataLayerRetriever()

    var cacheBacking: [HostedDataLayerCacheItem]? = []
    var cache: [HostedDataLayerCacheItem]? {
        get {
            return cacheBacking
        }

        set {
            if var newValue = newValue,
               newValue != self.cache {
                while newValue.count > TealiumValue.hdlCacheSizeMax {
                    newValue.removeFirst()
                }
                self.tempCache = newValue
                self.diskStorage.save(newValue, completion: nil)
            }
        }
    }

    var processed = [String]()
    public var id = "HostedDataLayer"
    public var config: TealiumConfig
    public var data: [String: Any]?
    var diskStorage: TealiumDiskStorageProtocol
    var failingDataLayerItems = Set<String>()

    var baseURL: String {
        return "https://tags.tiqcdn.com/dle/\(config.account)/\(config.profile)/"
    }

    required public init(config: TealiumConfig, delegate: ModuleDelegate?, diskStorage: TealiumDiskStorageProtocol?, completion: (ModuleResult) -> Void) {
        self.config = config
        self.diskStorage = diskStorage ?? TealiumDiskStorage(config: config, forModule: "hdl")
        if let cache = self.diskStorage.retrieve(as: [HostedDataLayerCacheItem].self) {
            self.cache = cache
        }
    }

    func expireCache(referenceDate date: Date = Date()) {
        let expiry = config.hostedDataLayerExpiry
        if let cache = self.cache,
           !cache.isEmpty {
            var components = DateComponents()
            components.calendar = Calendar.autoupdatingCurrent
            components.setValue(-expiry.0, for: expiry.unit.component)
            let sinceDate = Calendar(identifier: .gregorian).date(byAdding: components, to: date)

            self.cache = cache.filter({
                guard let sinceDate = sinceDate else {
                    return true
                }
                return $0.retrievalDate ?? Date() > sinceDate
            })
        }
    }

    public func shouldQueue(request: TealiumRequest) -> (Bool, [String: Any]?) {

        guard let dispatch = request as? TealiumTrackRequest else {
            return(false, nil)
        }

        if processed.contains(dispatch.uuid) {
            return(false, nil)
        }

        guard let url = getURL(for: dispatch) else {
            return(false, nil)
        }

        guard let dispatchKey = self.extractKey(from: dispatch) else {
            return(false, nil)
        }

        guard let itemId = dispatch.trackDictionary[dispatchKey] as? String else {
            return(false, nil)
        }

        guard failingDataLayerItems.contains("\(itemId)") == false else {
            return (false, ["hosted_data_layer_error": "Data layer item \(itemId).json does not exist"])
        }

        expireCache()

        if let existingCache = cache?["\(itemId)"] {
            processed.append(dispatch.uuid)
            return(false, existingCache)
        }

        // What happens if queue is released due to a release event but there's no data? Do we save the request for later and send it out of order?

        retrieveAndRetry(url: url, dispatch: dispatch, itemId: itemId, maxRetries: 5)

        return (true, ["queue_reason": "Awaiting HDL response"])
    }

    func retrieveAndRetry(url: URL,
                          dispatch: TealiumTrackRequest,
                          itemId: String,
                          maxRetries: Int,
                          current: Int = 0) {
        retriever.getData(for: url) { result in
            switch result {
            case .failure(let error):
                if let error = error as? HostedDataLayerError, [HostedDataLayerError.unableToDecodeData, HostedDataLayerError.emptyResponse].contains(error) {
                    self.processed.append(dispatch.uuid)
                    self.failingDataLayerItems.insert("\(itemId)")
                    return
                }
                if current < maxRetries {
                    TealiumQueues.backgroundSerialQueue.asyncAfter(deadline: .now() + Double(Int.random(in: 10...30))) {
                        self.retrieveAndRetry(url: url, dispatch: dispatch, itemId: itemId, maxRetries: maxRetries, current: current + 1)
                    }
                } else {
                    self.failingDataLayerItems.insert(itemId)
                }
            case .success(let data):
                let cacheItem = HostedDataLayerCacheItem(id: "\(itemId)", data: data)
                self.cache?.append(cacheItem)
            }
        }
    }

    public func shouldDrop(request: TealiumRequest) -> Bool {
        return false
    }

    public func shouldPurge(request: TealiumRequest) -> Bool {
        return false
    }

    func extractKey(from dispatch: TealiumTrackRequest) -> String? {
        guard let keys = config.hostedDataLayerKeys else {
            return nil
        }

        guard let event = dispatch.event else {
            return nil
        }

        guard let dispatchKey = keys[event] else {
            return nil
        }
        return dispatchKey
    }

    func getURL(for dispatch: TealiumTrackRequest) -> URL? {
        guard let dispatchKey = extractKey(from: dispatch) else {
            return nil
        }

        guard let lookupValue = dispatch.trackDictionary[dispatchKey] else {
            return nil
        }

        return URL(string: "\(baseURL)\(lookupValue).json")
    }

}

enum HostedDataLayerError: Error {
    case unknownResponseType
    case emptyResponse
    case unableToDecodeData
}

protocol HostedDataLayerRetrieverProtocol {
    var session: URLSessionProtocol { get set }
    func getData(for url: URL,
                 completion: @escaping ((Result<[String: Any], Error>) -> Void))
}

class HostedDataLayerRetriever: HostedDataLayerRetrieverProtocol {

    var session: URLSessionProtocol = URLSession(configuration: .ephemeral)

    func getData(for url: URL,
                 completion: @escaping ((Result<[String: Any], Error>) -> Void)) {

        session.tealiumDataTask(with: url) { result in
            switch result {
            case .success(let response):
                guard let data = response.1 else {
                    completion(.failure(HostedDataLayerError.emptyResponse))
                    return
                }

                guard let decodedData = (try? JSONDecoder().decode(AnyDecodable.self, from: data))?.value as? [String: Any] else {
                    completion(.failure(HostedDataLayerError.unableToDecodeData))
                    return
                }

                completion(.success(decodedData))
            case .failure(let error):
                completion(.failure(error))
            }
        }.resume()
    }

}
