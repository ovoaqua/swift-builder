//
//  MockHDLDiskStorage.swift
//  tealium-swift
//
//  Created by Craig Rouse on 15/07/2020.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

import Foundation
@testable import TealiumCore

class MockHDLDiskStorageFullCache: TealiumDiskStorageProtocol {

    var mockCache = [HostedDataLayerCacheItem]()

    init() {
        for _ in 0...50 {
            mockCache.append(HostedDataLayerCacheItem(id: "\(Int.random(in: 0...10000))", data: ["product_name": "test"]))
        }
    }

    func append(_ data: [String: Any], fileName: String, completion: TealiumCompletion?) { }

    func update<T>(value: Any, for key: String, as type: T.Type, completion: TealiumCompletion?) where T: Decodable, T: Encodable { }

    func save(_ data: AnyCodable, completion: TealiumCompletion?) { }

    func save(_ data: AnyCodable, fileName: String, completion: TealiumCompletion?) { }

    func save<T>(_ data: T, completion: TealiumCompletion?) where T: Encodable {
        guard T.self == [HostedDataLayerCacheItem].self,
            let data = data as? [HostedDataLayerCacheItem] else {
                return
        }
        
        self.mockCache = data
        
        completion?(true, nil, nil)
    }

    func save<T>(_ data: T, fileName: String, completion: TealiumCompletion?) where T: Encodable { }

    func append<T>(_ data: T, completion: TealiumCompletion?) where T: Decodable, T: Encodable { }

    func append<T>(_ data: T, fileName: String, completion: TealiumCompletion?) where T: Decodable, T: Encodable { }

    func retrieve<T>(as type: T.Type) -> T? where T: Decodable {
        guard T.self == [HostedDataLayerCacheItem].self else {
            return nil
        }
        return self.mockCache as? T
    }

    func retrieve<T>(_ fileName: String, as type: T.Type) -> T? where T: Decodable {
        return nil
    }

    func retrieve(fileName: String, completion: (Bool, [String: Any]?, Error?) -> Void) { }

    func append(_ data: [String: Any], forKey: String, fileName: String, completion: TealiumCompletion?) { }

    func delete(completion: TealiumCompletion?) { }

    func totalSizeSavedData() -> String? {
        return "1000"
    }

    func saveStringToDefaults(key: String, value: String) { }

    func getStringFromDefaults(key: String) -> String? {
        return ""
    }

    func saveToDefaults(key: String, value: Any) { }

    func getFromDefaults(key: String) -> Any? {
        return ""
    }

    func removeFromDefaults(key: String) { }

    func canWrite() -> Bool {
        return true
    }
}
