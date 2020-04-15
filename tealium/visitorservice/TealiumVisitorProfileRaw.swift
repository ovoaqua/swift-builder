//
//  TealiumVisitorProfileRaw.swift
//  TestHost
//
//  Created by Christina S on 4/14/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public struct TealiumVisitorProfileRaw: Codable {
    public var audiences: [String: String]?
    public var badges: [String: Bool]?
    public var dates: [String: Double]?
    public var flags: [String: Bool]?
    public var flagLists: [String: [Bool]]?
    public var metrics: [String: Double]?
    public var metricLists: [String: [Double]]?
    public var metricSets: [String: [String: Float]]?
    public var properties: [String: String]?
    public var propertyLists: [String: [String]]?
    public var propertySets: [String: Set<String>]?
    public var currentVisit: CurrentVisitProfileRaw?

    enum CodingKeys: String, CodingKey {
        case audiences
        case badges
        case dates
        case flags
        case flagLists = "flag_lists"
        case metrics
        case metricLists =  "metric_lists"
        case metricSets = "metric_sets"
        case properties
        case propertyLists = "property_lists"
        case propertySets = "property_sets"
        case currentVisit = "current_visit"
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        audiences = try values.decodeIfPresent([String: String].self, forKey: .audiences)
        badges = try values.decodeIfPresent([String: Bool].self, forKey: .badges)
        dates = try values.decodeIfPresent([String: Double].self, forKey: .dates)
        flags = try values.decodeIfPresent([String: Bool].self, forKey: .flags)
        flagLists = try values.decodeIfPresent([String: [Bool]].self, forKey: .flagLists)
        metrics = try values.decodeIfPresent([String: Double].self, forKey: .metrics)
        metricLists = try values.decodeIfPresent([String: [Double]].self, forKey: .metricLists)
        metricSets = try values.decodeIfPresent([String: [String: Float]].self, forKey: .metricSets)
        properties = try values.decodeIfPresent([String: String].self, forKey: .properties)
        propertyLists = try values.decodeIfPresent([String: [String]].self, forKey: .propertyLists)
        propertySets = try values.decodeIfPresent([String: Set<String>].self, forKey: .propertySets)
        currentVisit = try values.decodeIfPresent(CurrentVisitProfileRaw.self, forKey: .currentVisit)
    }
}

public struct CurrentVisitProfileRaw: Codable {
    public var dates: [String: Double]?
    public var flags: [String: Bool]?
    public var flagLists: [String: [Bool]]?
    public var metrics: [String: Double]?
    public var metricLists: [String: [Double]]?
    public var metricSets: [String: [String: Float]]?
    public var properties: [String: String]?
    public var propertyLists: [String: [String]]?
    public var propertySets: [String: Set<String>]?

    enum CodingKeys: String, CodingKey {
        case dates
        case flags
        case flagLists = "flag_lists"
        case metrics
        case metricLists =  "metric_lists"
        case metricSets = "metric_sets"
        case properties
        case propertyLists = "property_lists"
        case propertySets = "property_sets"
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        dates = try values.decodeIfPresent([String: Double].self, forKey: .dates)
        flags = try values.decodeIfPresent([String: Bool].self, forKey: .flags)
        flagLists = try values.decodeIfPresent([String: [Bool]].self, forKey: .flagLists)
        metrics = try values.decodeIfPresent([String: Double].self, forKey: .metrics)
        metricLists = try values.decodeIfPresent([String: [Double]].self, forKey: .metricLists)
        metricSets = try values.decodeIfPresent([String: [String: Float]].self, forKey: .metricSets)
        properties = try values.decodeIfPresent([String: String].self, forKey: .properties)
        propertyLists = try values.decodeIfPresent([String: [String]].self, forKey: .propertyLists)
        propertySets = try values.decodeIfPresent([String: Set<String>].self, forKey: .propertySets)
    }
}
