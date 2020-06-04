//
//  TealiumRemoteCommandProtocols.swift
//  TealiumRemoteCommands
//
//  Created by Christina S on 6/2/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

#if os(iOS)
import Foundation
#if remotecommands
import TealiumCore
#endif

public protocol TealiumRemoteCommandsManagerProtocol {
    var commands: RemoteCommandArray { get set }
    func add(_ remoteCommand: TealiumRemoteCommandProtocol)
    func disable()
    func remove(commandWithId: String)
    func triggerCommandFrom(request: URLRequest) -> TealiumRemoteCommandsError?
    func triggerCommandFrom(notification: Notification)
}

public protocol TealiumRemoteCommandProtocol {
    var commandId: String { get }
    var remoteCommandCompletion: TealiumRemoteCommandCompletion { get set }
    var delegate: TealiumRemoteCommandDelegate? { get set }
    var description: String? { get set }
    func completeWith(response: TealiumRemoteCommandResponseProtocol)
    static func sendCompletionNotification(for commandId: String,
        response: TealiumRemoteCommandResponseProtocol)
}

public protocol TealiumRemoteCommandResponseProtocol {
    func payload() -> [String: Any]
    var responseId: String? { get }
    var error: Error? { get set }
    var status: Int { get set }
    var data: Data? { get set }
    var urlResponse: URLResponse? { get set }
    var hasCustomCompletionHandler: Bool { get set }
}

public protocol TealiumRemoteCommandDelegate: class {

    /// Triggers the completion block registered for a specific remote command
    ///
    /// - Parameters:
    ///     - command: `TealiumRemoteCommandd` to be executed
    ///     - response: `TealiumRemoteCommandResponse` object passed back from TiQ. If the command needs to explictly handle the response (e.g. data needs passing back to webview),
    ///      it must set the "hasCustomCompletionHandler" flag, otherwise the completion notification will be sent automatically
    func tealiumRemoteCommandRequestsExecution(_ command: TealiumRemoteCommandProtocol,
                                               response: TealiumRemoteCommandResponseProtocol)
}

#endif
