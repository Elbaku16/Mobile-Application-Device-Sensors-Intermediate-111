//
//  ActivitySummary.swift
//  TrailmarkCore
//
//  Created by Lenin Baku Cortez Hernandez on 11/08/26.
//

import Foundation

public struct ActivitySummary: Sendable, Equatable {
    public let steps: Double
    public let distanceMeters: Double
    public let activeEnergyKcal: Double

    public init(steps: Double, distanceMeters: Double, activeEnergyKcal: Double) {
        self.steps = steps
        self.distanceMeters = distanceMeters
        self.activeEnergyKcal = activeEnergyKcal
    }
}
