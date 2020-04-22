//
//  EventDataManager.swift
//  TealiumSwift
//
//  Created by Craig Rouse on 4/21/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public enum Expiration {
    case session
    case untilRestart
    case forever
    case after(Date)
    case afterCustom((TimeUnit, Int))

    public var date: Date {
        var components = DateComponents()
        components.calendar = Calendar.autoupdatingCurrent
        let currentDate = Date()
        switch self {
        case .after(let date):
            return date
        case .forever:
         components.setValue(100, for: .year)
         return Calendar(identifier: .gregorian).date(byAdding: components, to: currentDate)!
     case .afterCustom((let unit, let value)):
        components.setValue(value, for: map(unit))
        return Calendar(identifier: .gregorian).date(byAdding: components, to: currentDate)!
    default:
        return Date()
        }
    }

    private func map(_ unit: TimeUnit) -> Calendar.Component {
        switch unit {
        case .minutes:
            return .minute
        case .hours:
            return .hour
        case .days:
            return .day
        case .months:
            return .month
        case .years:
            return .year
        }
    }

}

public enum TimeUnit {
    case minutes
    case hours
    case days
    case months
    case years
}

public class EventDataManager {

    // need to check for existing session data in storage first
    var sessionData = [String: Any]()
    var untilRestartData = [String: Any]()
    var data = Set<EventDataItem>()
    
    private var persistentDataStorage: EventData? {
        get {
            return self.diskStorage.retrieve(as: EventData.self)?.removeExpired()
        }

        set {
            if let newData = newValue?.removeExpired() {
                self.diskStorage.save(newData, completion: nil)
            }
        }
    }

    var diskStorage: TealiumDiskStorageProtocol
    var isLoaded: Atomic<Bool> = Atomic(value: false)

    public var allEventData: [String: Any] {
        get {
            var allData = [String: Any]()
            if let persistentData = self.persistentDataStorage {
                allData += persistentData.allData
            }
            allData += self.untilRestartData
            allData += self.sessionData
            return allData
        }
        set {
            self.add(data: newValue, expiration: .forever)
        }
    }

    public init(config: TealiumConfig,
                diskStorage: TealiumDiskStorageProtocol? = nil) {
        self.diskStorage = TealiumDiskStorage(config: config, forModule: "eventdata")
        guard let eventData = diskStorage?.retrieve(as: EventData.self) else {
            self.persistentDataStorage = EventData()
            return
        }
        self.persistentDataStorage = eventData
    }

    public func add(key: String,
        value: Any,
        expiration: Expiration) {
        self.add(data: [key: value], expiration: expiration)
    }

    public func add(data: [String: Any],
        expiration: Expiration) {
        switch expiration {
        case .session:
            print("⏰adding session data")
            self.sessionData += data
            sessionData.forEach {
                print("key=\($0.key), value=\($0.value)")
            }
            print("⏰should we wait on this until session mgr in Android is finished? it is done in swift - should we merge into this branch?")
        case .untilRestart:
            print("♻️adding restart data")
            self.untilRestartData += data
            untilRestartData.forEach {
                print("key=\($0.key), value=\($0.value)")
            }
        default:
            print("🙃adding default w exp date: \(expiration.date)")
            data.forEach {
                print("key=\($0.key), value=\($0.value)")
            }
            self.persistentDataStorage?.insertNew(from: data, expires: expiration.date)
        }
    }

    func expireSessionData() {
        print("⏰expiring session data: ")
        sessionData.forEach {
            print("key=\($0.key), value=\($0.value)")
        }
        print("⏰should we wait on this until session mgr in Android is finished? it is done in swift - should we merge into this branch?")
    }
    
    func delete(forKey key: String) {
        self.persistentDataStorage?.remove(key: key)
    }
    
    func deleteAll() {
        self.persistentDataStorage?.removeAll()
    }


}
