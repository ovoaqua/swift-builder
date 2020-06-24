//
//  TealiumRemoteCommandsManager.swift
//  tealium-swift
//
//  Created by Jonathan Wong on 1/31/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.

#if os(iOS)
import Foundation
#if remotecommands
import TealiumCore
#endif

public typealias RemoteCommandArray = [TealiumRemoteCommandProtocol]

/// Manages instances of TealiumRemoteCommand
public class TealiumRemoteCommandsManager: NSObject, TealiumRemoteCommandsManagerProtocol {
    
    weak var queue = TealiumQueues.backgroundSerialQueue
    public var commands = RemoteCommandArray()
    var isEnabled = false
    weak public var moduleDelegate: TealiumModuleDelegate?
    static var pendingResponses = Atomic<[String: Bool]>(value: [String: Bool]())

    public init(delegate: TealiumModuleDelegate?) {
        moduleDelegate = delegate
    }
    
    /// Adds a remote command for later execution.
    ///
    /// - Parameter remoteCommand: `TealiumRemoteCommand` to be added for later execution
    public func add(_ remoteCommand: TealiumRemoteCommandProtocol) {
        // NOTE: Multiple commands with the same command id are possible - OK
        var remoteCommand = remoteCommand
        remoteCommand.delegate = self
        commands.append(remoteCommand)
    }

    /// Removes a Remote Command so it can no longer be called.
    ///
    /// - Parameter commandId: `String` containing the command ID to be removed
    public func remove(commandWithId: String) {
        commands.removeCommand(commandWithId)
    }

    /// Disables Remote Commands and removes all previously-added Remote Commands so they can no longer be executed.
    public func removeAll() {
        commands.removeAll()
    }
    
    public func triggerCommand(with data: [String: Any]) {
        guard let request = data[TealiumKey.tagmanagementNotification] as? URLRequest else {
            return
        }
        triggerCommand(from: request)
    }

    /// Trigger an associated remote command from a url request.
    ///￼
    /// - Parameter request: `URLRequest` to check for a remote command.
    /// - Returns: `TealiumRemoteCommandsError` if unable to trigger a remote command. If nil is returned,
    ///     then call was a successfully triggered remote command.
    @discardableResult
    public func triggerCommand(from request: URLRequest) -> TealiumRemoteCommandsError? {
        if request.url?.scheme != TealiumKey.tealiumURLScheme {
            return TealiumRemoteCommandsError.invalidScheme
        }
        guard let commandId = request.url?.host else {
            return TealiumRemoteCommandsError.noCommandIdFound
        }
        guard let command = commands[commandId] else {
            return TealiumRemoteCommandsError.noCommandForCommandIdFound
        }
        guard let response = TealiumRemoteCommandResponse(request: request) else {
            return TealiumRemoteCommandsError.requestNotProperlyFormatted
        }
        if let responseId = response.responseId {
            TealiumRemoteCommandsManager.pendingResponses.value[responseId] = true
        }
        command.complete(with: response)
        return nil
    }
}

extension TealiumRemoteCommandsManager: TealiumRemoteCommandDelegate {

    /// Triggers the completion block registered for a specific remote command.
    ///
    /// - Parameters:
    ///     - command: `TealiumRemoteCommand` to be executed
    ///     - response: `TealiumRemoteCommandResponse` object passed back from TiQ. If the command needs to explictly handle the response (e.g. data needs passing back to webview),
    ///      it must set the "hasCustomCompletionHandler" flag, otherwise the completion notification will be sent automatically
    public func tealiumRemoteCommandRequestsExecution(_ command: TealiumRemoteCommandProtocol,
                                               response: TealiumRemoteCommandResponseProtocol) {
        self.queue?.async {
            command.remoteCommandCompletion(response)
            // this will send the completion notification, if it wasn't explictly handled by the command
            if !response.hasCustomCompletionHandler {
                TealiumRemoteCommand.sendRemoteCommandResponse(for: command.commandId,
                                                               response: response,
                                                               delegate: self.moduleDelegate)
            }
        }
    }
}
#endif
