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

    var baseURL: String {
        return "https://tags.tiqcdn.com/dle/\(config.account)/\(config.profile)/"
    }

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

        }
    }

}
