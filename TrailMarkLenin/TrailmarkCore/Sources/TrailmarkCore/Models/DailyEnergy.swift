//
//  DailyEnergy.swift
//  TrailmarkCore
//
//  Created by Lenin Baku Cortez Hernandez on 13/08/26.
//

import Foundation

public struct DailyEnergy: Identifiable, Sendable, Equatable {
    public var id: Date { date }
    public let date: Date
    public let kcal: Double

    public init(date: Date, kcal: Double) {
        self.date = date
        self.kcal = kcal
    }
}
