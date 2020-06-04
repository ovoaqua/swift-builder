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

// Track request type
public typealias RemoteCommandArray = [TealiumRemoteCommandProtocol]

/// Manages instances of TealiumRemoteCommand
public class TealiumRemoteCommandsManager: NSObject, TealiumRemoteCommandsManagerProtocol {
    
    weak var queue = TealiumQueues.backgroundSerialQueue
    public var commands = RemoteCommandArray()
    var isEnabled = false
    static var pendingResponses = Atomic<[String: Bool]>(value: [String: Bool]())

    public override init() {
        isEnabled = true
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
    public func disable() {
        commands.removeAll()
        isEnabled = false
    }

    //❓Can we remove this? not being used
    /// Trigger an associated remote command from a string representation of a url request. Function
    ///     will presume the string is escaped, if not, will attempt to escape string
    ///     with .urlQueryAllowed. NOTE: using .urlHostAllowed for escaping will not work.
    ///￼
    /// - Parameter urlString:`String` containing a URL including host, ie: tealium://commandId?request={}...
    /// - Returns: Error if unable to trigger a remote command. Can ignore if the url was not
    ///     intended for a remote command.
    public func triggerCommandFrom(urlString: String) -> TealiumRemoteCommandsError? {
        var urlInitial = URL(string: urlString)
        if urlInitial == nil {
            guard let escapedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                return TealiumRemoteCommandsError.requestNotProperlyFormatted
            }
            urlInitial = URL(string: escapedString)
        }
        guard let url = urlInitial else {
            return TealiumRemoteCommandsError.requestNotProperlyFormatted
        }
        let request = URLRequest(url: url)

        return triggerCommandFrom(request: request)
    }

    public func triggerCommandFrom(notification: Notification) {
        guard let request = notification.userInfo?[TealiumKey.tagmanagementNotification] as? URLRequest else {
            return
        }
        triggerCommandFrom(request: request)
    }

    /// Trigger an associated remote command from a url request.
    ///￼
    /// - Parameter request: `URLRequest` to check for a remote command.
    /// - Returns: `TealiumRemoteCommandsError` if unable to trigger a remote command. If nil is returned,
    ///     then call was a successfully triggered remote command.
    @discardableResult
    public func triggerCommandFrom(request: URLRequest) -> TealiumRemoteCommandsError? {

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

        if isEnabled == false {
            // Was valid remote command, but we're disabled at the moment.
            return nil
        }

        if let responseId = response.responseId {
            TealiumRemoteCommandsManager.pendingResponses.value[responseId] = true
        }
        command.completeWith(response: response)

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
                TealiumRemoteCommand.sendCompletionNotification(for: command.commandId, response: response)
            }
        }
    }
}
#endif
