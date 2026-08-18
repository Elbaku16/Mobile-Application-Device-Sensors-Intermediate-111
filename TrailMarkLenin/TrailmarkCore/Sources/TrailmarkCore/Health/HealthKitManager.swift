//
//  HealthKitManager.swift
//  TrailmarkCore
//
//  Created by Lenin Baku Cortez Hernandez on 11/08/26.
//

import Foundation
import HealthKit
import Observation

@MainActor
@Observable
public final class HealthKitManager {
    public private(set) var todaySummary: ActivitySummary?
    public private(set) var authorizationDenied: Bool = false
    public private(set) var isLoading: Bool = false

    private let store = HKHealthStore()

    public init() {}

    public var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    private var readTypes: Set<HKObjectType> {
        [
            HKQuantityType(.stepCount),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.activeEnergyBurned)
        ]
    }

    public func requestAuthorization() async {
        guard isHealthDataAvailable else {
            authorizationDenied = true
            return
        }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            await refreshToday()
        } catch {
            authorizationDenied = true
        }
    }

    public func refreshToday() async {
        isLoading = true
        defer { isLoading = false }

        async let steps = sumToday(for: HKQuantityType(.stepCount), unit: .count())
        async let distance = sumToday(for: HKQuantityType(.distanceWalkingRunning), unit: .meter())
        async let energy = sumToday(for: HKQuantityType(.activeEnergyBurned), unit: .kilocalorie())

        let (s, d, e) = await (steps, distance, energy)

        todaySummary = ActivitySummary(
            steps: s ?? 0,
            distanceMeters: d ?? 0,
            activeEnergyKcal: e ?? 0
        )
    }

    public func activeEnergy(from start: Date, to end: Date) async -> Double {
        await sumToday(for: HKQuantityType(.activeEnergyBurned), unit: .kilocalorie(), start: start, end: end) ?? 0
    }

    private func sumToday(for type: HKQuantityType, unit: HKUnit, start: Date? = nil, end: Date? = nil) async -> Double? {
        let calendar = Calendar.current
        let startDate = start ?? calendar.startOfDay(for: Date())
        let endDate = end ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, _ in
                let value = statistics?.sumQuantity()?.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }
}
