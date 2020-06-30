//
//  TealiumRemoteHTTPCommand.swift
//  tealium-swift
//
//  Created by Craig Rouse on 3/4/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//
#if os(iOS)
import Foundation
#if remotecommands
import TealiumCore
#endif

class TealiumRemoteHTTPCommand: TealiumRemoteCommand {

    /// - Returns:`TealiumRemoteHTTPCommand`
    class func create(with delegate: TealiumModuleDelegate?) -> TealiumRemoteCommandProtocol {
        return TealiumRemoteCommand(commandId: TealiumRemoteCommandsKey.commandId,
                                    description: "For processing tag-triggered HTTP requests") { response in
            var response = response
            response.hasCustomCompletionHandler = true
            let requestInfo = TealiumRemoteHTTPCommand.httpRequest(from: response.payload())

            guard let request = requestInfo.request else {
                return
            }

            let task = TealiumRemoteCommand.urlSession.tealiumDataTask(with: request,
                                                                       completionHandler: { data, urlResponse, error in
                                                                        // Legacy status reporting
                                                                        if let err = error {
                                                                            response.error = err
                                                                            response.status = TealiumRemoteCommandStatusCode.failure.rawValue
                                                                        } else {
                                                                            response.status = TealiumRemoteCommandStatusCode.success.rawValue
                                                                        }
                                                                        if data == nil {
                                                                            response.status = TealiumRemoteCommandStatusCode.noContent.rawValue
                                                                        }
                                                                        if urlResponse == nil {
                                                                            response.status = TealiumRemoteCommandStatusCode.failure.rawValue
                                                                        }
                                                                        response.urlResponse = urlResponse
                                                                        response.data = data
                                                                        TealiumRemoteCommand.sendRemoteCommandResponse(for: TealiumRemoteCommandsKey.commandId, response: response, delegate: delegate)
                                                                       })

            task.resume()
        }
    }

    /// Forms a URLRequest from a dictionary payload containing predetermined config keys
    ///￼
    /// - Parameter payload: [String: Any] payload representing a set of key-value pairs to be sent with the URLRequest
    /// - Returns: `(URLRequest?, Error?)`
    class func httpRequest(from payload: [String: Any]) -> (request: URLRequest?, error: Error?) {
        guard let urlStringValue = payload[TealiumRemoteCommandsKey.url] as? String else {
            // This response is not intended for use as an HTTP command
            return (nil, TealiumRemoteCommandResponseError.missingURLTarget)
        }

        guard let method = payload[TealiumRemoteCommandsKey.method] as? String else {
            // No idea what sort of URL call we should be making
            return (nil, TealiumRemoteCommandResponseError.missingURLMethod)
        }

        var urlComponents = URLComponents(string: urlStringValue)

        if let paramsData = payload[TealiumRemoteCommandsKey.parameters] as? [String: Any] {
            let queryItems = TealiumRemoteHTTPCommand.queryItems(from: paramsData)
            urlComponents?.queryItems = queryItems
        }

        guard let url = urlComponents?.url else {
            return (nil, TealiumRemoteCommandResponseError.couldNotConvertDataToURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        if let headersData = payload[TealiumRemoteCommandsKey.headers] as? [String: Any] {
            request.headersFrom(dictionary: headersData)
        }
        if let body = payload[TealiumRemoteCommandsKey.body] as? String {
            request.httpBody = body.data(using: .utf8)
            request.addValue("\([UInt8](body.utf8))", forHTTPHeaderField: "Content-Length")
        }
        if let body = payload[TealiumRemoteCommandsKey.body] as? [String: Any] {
            let jsonData = try? JSONSerialization.data(withJSONObject: body)
            request.httpBody = jsonData
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        }

        if let authenticationData = payload[TealiumRemoteCommandsKey.authenticate] as? [String: Any] {
            if let username = authenticationData[TealiumRemoteCommandsKey.username] as? String,
               let password = authenticationData[TealiumRemoteCommandsKey.password] as? String {
                let loginString = "\(username):\(password)"
                let loginData = loginString.data(using: String.Encoding.utf8)!
                let base64LoginString = loginData.base64EncodedString()
                request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")

            }
        }

        return (request, nil)
    }

    /// Returns sorted queryItems from a dictionary.
    ///￼
    /// - Parameter dictionary: `[String:Any]`
    /// - Returns: Sorted `[URLQueryItem]` array by dictionary keys
    class func queryItems(from dictionary: [String: Any]) -> [URLQueryItem] {
        var queryItems = [URLQueryItem]()
        let sortedKeys = Array(dictionary.keys).sorted(by: <)
        for key in sortedKeys {
            // Convert all values to string
            let value = String(describing: dictionary[key]!)
            let queryItem = URLQueryItem(name: key, value: value)
            queryItems.append(queryItem)
        }
        return queryItems
    }

}
#endif
