//
//  TealiumLifecycleSession.swift
//  tealium-swift
//
//  Created by Craig Rouse on 05/07/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

enum TealiumLifecycleSessionKey {
    static let wakeDate = "wake"
    static let sleepDate = "sleep"
    static let secondsElapsed = "seconds"
    static let wasLaunch = "wasLaunch"
}

// Represents a serializable block of time between a given wake and a sleep
public struct TealiumLifecycleSession: Codable, Equatable {

    var appVersion: String = TealiumLifecycleSession.currentAppVersion
    var wakeDate: Date?
    var sleepDate: Date? {
        didSet {
            guard let wake = wakeDate else {
                return
            }
            guard let sleep = sleepDate else {
                return
            }
            let milliseconds = sleep.timeIntervalSince(wake)
            secondsElapsed = Int(milliseconds)
        }
    }
    var secondsElapsed: Int = 0
    var wasLaunch = false

    init(launchDate: Date) {
        self.wakeDate = launchDate
        self.wasLaunch = true
    }

    init(wakeDate: Date) {
        self.wakeDate = wakeDate
    }

    public init?(coder aDecoder: NSCoder) {
        self.wakeDate = aDecoder.decodeObject(forKey: TealiumLifecycleSessionKey.wakeDate) as? Date
        self.sleepDate = aDecoder.decodeObject(forKey: TealiumLifecycleSessionKey.sleepDate) as? Date
        self.secondsElapsed = aDecoder.decodeInteger(forKey: TealiumLifecycleSessionKey.secondsElapsed) as Int
        self.wasLaunch = aDecoder.decodeBool(forKey: TealiumLifecycleSessionKey.wasLaunch) as Bool
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.wakeDate, forKey: TealiumLifecycleSessionKey.wakeDate)
        aCoder.encode(self.sleepDate, forKey: TealiumLifecycleSessionKey.sleepDate)
        aCoder.encode(self.secondsElapsed, forKey: TealiumLifecycleSessionKey.secondsElapsed)
        aCoder.encode(self.wasLaunch, forKey: TealiumLifecycleSessionKey.wasLaunch)
    }
    
    static var currentAppVersion: String {
        return Bundle.main.version ?? "(unknown)"
    }

    // Is this being used anywhere? Move to unit tests?
    public static func ==(lhs: TealiumLifecycleSession, rhs: TealiumLifecycleSession ) -> Bool {

        if lhs.wakeDate != rhs.wakeDate { return false }
        if lhs.sleepDate != rhs.sleepDate { return false }
        if lhs.secondsElapsed != rhs.secondsElapsed { return false }
        if lhs.wasLaunch != rhs.wasLaunch { return false }
        return true
    }
}
