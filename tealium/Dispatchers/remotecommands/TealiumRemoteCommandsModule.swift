//
//  TealiumRemoteCommandsModule.swift
//  tealium-swift
//
//  Created by Jason Koo on 3/13/17.
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

#if os(iOS)
import Foundation
#if remotecommands
import TealiumCore
#endif

public class TealiumRemoteCommandsModule: Dispatcher {
    
    public var moduleId: String = "Remote Commands"
    public var config: TealiumConfig
    public var isReady: Bool = false
    public var remoteCommands: TealiumRemoteCommandsManagerProtocol?
    var observer: NSObjectProtocol?
    var reservedCommandsAdded = false

    
    /// Provided for unit testing￼.
    ///
    /// - Parameter remoteCommands: Class instance conforming to `TealiumRemoteCommandsManagerProtocol`
    convenience init (config: TealiumConfig,
                      delegate: TealiumModuleDelegate,
                      remoteCommands: TealiumRemoteCommandsManagerProtocol? = nil) {
        self.init(config: config, delegate: delegate){ result in }
        self.remoteCommands = remoteCommands
    }
    
    public required init(config: TealiumConfig, delegate: TealiumModuleDelegate, completion: ModuleCompletion?) {
        self.config = config
        remoteCommands = remoteCommands ?? TealiumRemoteCommandsManager()
        updateReservedCommands(config: config)
        addCommandsFromConfig(config)
        enableNotifications()
    }

    public func updateConfig(_ request: TealiumUpdateConfigRequest) {
        let newConfig = request.config.copy
        if newConfig != self.config {
            self.config = newConfig
            let existingCommands = self.remoteCommands?.commands
            if let newCommands = newConfig.remoteCommands, newCommands.count > 0 {
                existingCommands?.forEach {
                    newConfig.addRemoteCommand($0)
                }
            }
        }
    }

    /// Allows Remote Commands to be added from the TealiumConfig object.
    ///￼
    /// - Parameter config: `TealiumConfig` object containing Remote Commands
    private func addCommandsFromConfig(_ config: TealiumConfig) {
        if let commands = config.remoteCommands {
            for command in commands {
                self.remoteCommands?.add(command)
            }
        }
    }

    /// Enables listeners for notifications from the Tag Management module (WebView).
    func enableNotifications() {
        guard observer == nil else {
            return
        }
        observer = NotificationCenter.default.addObserver(forName: Notification.Name.tagmanagement, object: nil, queue: OperationQueue.main) {
            self.remoteCommands?.triggerCommandFrom(notification: $0)
        }
    }

    /// Identifies if any built-in Remote Commands should be disabled.
    ///￼
    /// - Parameter config: `TealiumConfig` object containing flags indicating which built-in commands should be disabled.
    func updateReservedCommands(config: TealiumConfig) {
        guard reservedCommandsAdded == false else {
            return
        }
        // Default option
        var shouldDisable = false

        if let shouldDisableSetting = config.optionalData[TealiumRemoteCommandsKey.disableHTTP] as? Bool {
            shouldDisable = shouldDisableSetting
        }

        if shouldDisable == true {
            remoteCommands?.remove(commandWithId: TealiumRemoteCommandsKey.commandId)
        } else if remoteCommands?.commands[TealiumRemoteCommandsKey.commandId] == nil {
            let httpCommand = TealiumRemoteHTTPCommand.create()
            remoteCommands?.add(httpCommand)
        }
        reservedCommandsAdded = true
        // No further processing required - HTTP remote command already up.
    }
    
    @available(*, deprecated, message: "Reserved for future use.")
    public func dynamicTrack(_ request: TealiumRequest,
                             completion: ModuleCompletion?) {
    }

    deinit {
        if let observer = self.observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
#endif
