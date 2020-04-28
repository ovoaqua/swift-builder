//
//  SessionStarter.swift
//  TealiumCore
//
//  Created by Christina S on 4/27/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation


public protocol SessionStarterProtocol {
    var sessionURL: String { get }
    func sessionRequest(_ completion: @escaping (Result<HTTPURLResponse, Error>) -> Void)
    //func sessionRequest(_ completion: @escaping ((HTTPURLResponse?, String?) -> Void))
}

public struct SessionStarter: SessionStarterProtocol {
    
    var config: TealiumConfig
    var urlSession: URLSessionProtocol
    var logger: TealiumLogger
    
    public init(config: TealiumConfig,
                urlSession: URLSessionProtocol = URLSession.shared) {
        self.config = config
        self.urlSession = urlSession
        self.logger = TealiumLogger(loggerId: "SessionStarter", logLevel: config.logLevel ?? defaultTealiumLogLevel)
    }
    
    /// Sets the session URL
    public var sessionURL: String {
        let timestamp = Date().unixTimeMilliseconds
        return "\(TealiumKey.sessionBaseURL)\(config.account)/\(config.profile)/\(timestamp)&cb=\(timestamp)"
    }
    
    /// Requests a new session via utag.v.js
    public func sessionRequest(_ completion: @escaping (Result<HTTPURLResponse, Error>) -> Void = { _ in }) {
        print("requesting new session...")
        guard let url = URL(string: sessionURL) else {
            self.log(error: SessionError.invalidURL.description)
            return
        }
        urlSession.tealiumDataTask(with: url) { _, response, error in
            if error != nil {
                self.log(error: "\(SessionError.errorInRequest.description)\(String(describing: error?.localizedDescription))")
                completion(.failure(SessionError.errorInRequest))
                return
            }
            guard let response = response as? HTTPURLResponse,
                HttpStatusCodes(rawValue: response.statusCode) == .ok else {
                    self.log(error: SessionError.invalidResponse.description)
                    completion(.failure(SessionError.invalidResponse))
                return
            }
            completion(.success(response))
        }.resume()
    }
    
    /// - Parameter error: `String`
    func log(error: String) {
        logger.log(message: error, logLevel: .warnings)
    }
    
}


