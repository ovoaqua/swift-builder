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
            throw HostedDataLayerErrors.unableToDecodeData
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
    var cache: [HostedDataLayerCacheItem] = [] {
        willSet {
            if newValue != self.cache {
                self.diskStorage.save(newValue, completion: nil)
            }
        }
    }
    var processed = [String]()
    public var id = "HostedDataLayer"
    public var config: TealiumConfig
    public var data: [String: Any]?
    var diskStorage: TealiumDiskStorageProtocol

    let retriever = HostedDataLayerRetriever()

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

        guard let itemId = dispatch.trackDictionary[dispatchKey] else {
            return (false, nil)
        }

        if let existingCache = cache["\(itemId)"] {
            processed.append(dispatch.uuid)
            return(false, existingCache)
        }

        retriever.getData(for: url) { result in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let data):
                let cacheItem = HostedDataLayerCacheItem(id: "\(itemId)", data: data)
                self.cache.append(cacheItem)
            }
        }

        return (true, ["queue_reason": "Awaiting HDL response"])
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

enum HostedDataLayerErrors: Error {
    case unknownResponseType
    case emptyResponse
    case unableToDecodeData
}

class HostedDataLayerRetriever {

    let session = URLSession(configuration: .ephemeral)

    func getData(for url: URL,
                 completion: @escaping ((Result<[String: Any], Error>) -> Void)) {
        session.dataTask(with: url) { data, response, error in
            guard error == nil else {
                completion(.failure(error!))
                return
            }

            guard let response = response as? HTTPURLResponse, response.statusCode == HttpStatusCodes.ok.rawValue else {
                completion(.failure(HostedDataLayerErrors.unknownResponseType))
                return
            }

            guard let data = data else {
                completion(.failure(HostedDataLayerErrors.emptyResponse))
                return
            }

            guard let decodedData = (try? JSONDecoder().decode(AnyDecodable.self, from: data))?.value as? [String: Any] else {
                completion(.failure(HostedDataLayerErrors.unableToDecodeData))
                return
            }

            completion(.success(decodedData))

        }.resume()
    }

}
