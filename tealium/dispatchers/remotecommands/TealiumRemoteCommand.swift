//
//  TealiumRemoteCommand.swift
//  tealium-swift
//
//  Created by Jonathan Wong on 1/31/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//
#if os(iOS)
import Foundation
#if remotecommands
import TealiumCore
#endif

public typealias TealiumRemoteCommandCompletion = ((_ response: TealiumRemoteCommandResponseProtocol) -> Void)

/// Designed to be subclassed. Allows Remote Commands to be created by host apps,
/// and called on-demand by the Tag Management module
open class TealiumRemoteCommand: TealiumRemoteCommandProtocol {

    public let commandId: String
    weak public var delegate: TealiumRemoteCommandDelegate?
    public var description: String?
    static var urlSession: URLSessionProtocol = URLSession.shared
    public var remoteCommandCompletion: TealiumRemoteCommandCompletion

    /// Constructor for a Tealium Remote Command.
    ///
    /// - Parameters:
    ///     - commandId: `String` identifier for command block.
    ///     - description: `String?` description of command.
    ///     - urlSession: `URLSessionProtocol`
    ///     - completion: The completion block to run when this remote command is triggered.
    public init(commandId: String,
                description: String?,
                completion : @escaping TealiumRemoteCommandCompletion) {

        self.commandId = commandId
        self.description = description
        self.remoteCommandCompletion = completion
    }

    /// Called when a Remote Command is ready for execution.
    ///￼
    /// - Parameter response: `TealiumRemoteCommandResponse` object containing information from the TiQ webview
    public func complete(with response: TealiumRemoteCommandResponseProtocol) {

        delegate?.tealiumRemoteCommandRequestsExecution(self,
                                                        response: response)

    }

    /// Generates response data for a specific Remote Command.
    ///
    /// - Parameters:
    ///     - commandId: `String` identifier for the Remote Command
    ///     - response: `TealiumRemoteCommandResponse` from the remote command to be passed back to the TiQ webview
    ///     - Returns: `[String: Any]?`  containing the encoded JavaScript string for the TiQ webview.
    class func remoteCommandResponse(for commandId: String,
                                     response: TealiumRemoteCommandResponseProtocol) -> [String: Any]? {
        guard let responseId = response.responseId else {
            return nil
        }
        var responseStr: String
        if let responseData = response.data {
            responseStr = String(data: responseData, encoding: .utf8)!
        } else {
            // keep previous behavior from obj-c library
            responseStr = "(null)"
        }
        let jsString = "try { utag.mobile.remote_api.response['\(commandId)']['\(responseId)']('\(String(describing: response.status))','\(responseStr)')} catch(err) {console.error(err)}"
        return [TealiumRemoteCommandsKey.jsCommand: jsString]
    }
    
    /// Sends Remote Command response data to the TiQ webview when
    /// the remote command has finished executing.
    ///
    /// - Parameters:
    ///     - commandId: `String` identifier for the Remote Command
    ///     - response: `TealiumRemoteCommandResponse` from the remote command to be passed back to the TiQ webview
    ///     - delegate: `TealiumModuleDelegate?`
    public class func sendRemoteCommandResponse(for commandId: String,
                                                response: TealiumRemoteCommandResponseProtocol,
                                                delegate: TealiumModuleDelegate?) {
        guard let responseId = response.responseId else {
            return
        }
        guard TealiumRemoteCommandsManager.pendingResponses.value[responseId] == true else {
            return
        }
        TealiumRemoteCommandsManager.pendingResponses.value[responseId] = nil
        guard let response = remoteCommandResponse(for: commandId,
                                                   response: response) else {
                                                    return
        }
        let request = TealiumRemoteCommandRequestResponse(data: response)
        delegate?.processRemoteCommandRequest(request)
    }
}
#endif
