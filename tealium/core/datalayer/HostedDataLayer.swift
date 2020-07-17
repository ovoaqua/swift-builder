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
    //    func requestData(for url: URL, completion: ((Result<[String: Any], Error>) -> Void))
}

struct HostedDataLayerCacheItem: Codable, Equatable {
    static func == (lhs: HostedDataLayerCacheItem, rhs: HostedDataLayerCacheItem) -> Bool {
        if let lhsData = lhs.data, let rhsData = rhs.data {
            return lhs.id == rhs.id && lhsData == rhsData
        } else {
            return lhs.id == rhs.id
        }
    }

    var id: String
    var data: [String: Any]?

    enum CodingKeys: String, CodingKey {
        case id
        case data
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let data = self.data?.encodable {
            try container.encode(id, forKey: .id)
            try container.encode(data, forKey: .data)
        }
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let id = try values.decode(String.self, forKey: .id)
        if let cacheItem = try values.decode(AnyDecodable.self, forKey: .data).value as? [String: Any] {
            self.id = id
            self.data = cacheItem
        } else {
            throw HostedDataLayerError.unableToDecodeData
        }
    }

    init(id: String,
         data: [String: Any]) {
        self.id = id
        self.data = data
    }
}

extension Array where Element == HostedDataLayerCacheItem {
    internal subscript(_ id: String) -> [String: Any]? {
        self.first { $0.id == id }?.data
    }
}

public extension TealiumConfig {

    var hostedDataLayerKeys: [String: String]? {
        get {
            options[TealiumKey.hostedDataLayerKeys] as? [String: String]
        }

        set {
            options[TealiumKey.hostedDataLayerKeys] = newValue
        }
    }

}

public class HostedDataLayer: HostedDataLayerProtocol {
    var retriever: HostedDataLayerRetrieverProtocol = HostedDataLayerRetriever()

    var tempCache: [HostedDataLayerCacheItem]? = []
    var cache: [HostedDataLayerCacheItem]? {
        get {
            self.tempCache
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
            self.tempCache = cache
        }
    }

    public func shouldQueue(request: TealiumRequest) -> (Bool, [String: Any]?) {

        guard let dispatch = request as? TealiumTrackRequest else {
            return(false, nil)
        }

        //        guard failingRequests[dispatch.uuid]

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

        if let existingCache = cache?["\(itemId)"] {
            processed.append(dispatch.uuid)
            return(false, existingCache)
        }

        // TODO: Keep track of requests for specific cache items. If it fails after 5 attempts, always allow the request to complete. If empty response received, always release.
        // What happens if queue is released due to a release event but there's no data? Do we save the request for later and send it out of order?
        //        retriever.getData(for: url) { result in
        //            switch result {
        //            case .failure(let error):
        //                if error as? HostedDataLayerError == HostedDataLayerError.unableToDecodeData {
        //                    self.processed.append(dispatch.uuid)
        //                    self.failingDataLayerItems.insert("\(itemId)")
        //                    return
        //                }
        //                self.failingRequests[dispatch.uuid] = self.failingRequests[dispatch.uuid] ?? 0
        //                self.failingRequests[dispatch.uuid]? += 1
        //                print(error.localizedDescription)
        //            case .success(let data):
        //                let cacheItem = HostedDataLayerCacheItem(id: "\(itemId)", data: data)
        //                self.cache?.append(cacheItem)
        //            }
        //        }

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
                    self.retrieveAndRetry(url: url, dispatch: dispatch, itemId: itemId, maxRetries: maxRetries, current: current + 1)
                } else {
                    self.failingDataLayerItems.insert(itemId)
                    print(error.localizedDescription)
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
