//
//  Journey.swift
//  TrailmarkCore
//
//  Created by Lenin Baku Cortez Hernandez on 15/08/26.
//

import Foundation

public struct Journey: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let startDate: Date
    public var endDate: Date?
    public var route: [Coordinate]
    public var memoIDs: [UUID]

    public init(id: UUID = UUID(), startDate: Date = Date(), endDate: Date? = nil, route: [Coordinate] = [], memoIDs: [UUID] = []) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.route = route
        self.memoIDs = memoIDs
    }

    public var isActive: Bool { endDate == nil }
}
