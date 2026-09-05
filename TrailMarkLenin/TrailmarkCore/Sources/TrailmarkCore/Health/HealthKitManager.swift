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
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.heartRate)
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

    // MARK: - Live vitals (para el watch)

    public private(set) var liveHeartRate: Double?
    public private(set) var liveSteps: Double = 0
    public private(set) var liveActiveEnergy: Double = 0

    private var heartRateQuery: HKAnchoredObjectQuery?
    private var stepsQuery: HKAnchoredObjectQuery?
    private var energyQuery: HKAnchoredObjectQuery?

    private let stepsAccumulator = Accumulator()
    private let energyAccumulator = Accumulator()

    public func startLiveVitals() {
        startHeartRateQuery()
        startStepsQuery()
        startEnergyQuery()
    }

    public func stopLiveVitals() {
        if let heartRateQuery { store.stop(heartRateQuery) }
        if let stepsQuery { store.stop(stepsQuery) }
        if let energyQuery { store.stop(energyQuery) }
    }

    private func startHeartRateQuery() {
        let type = HKQuantityType(.heartRate)
        let unit = HKUnit.count().unitDivided(by: .minute())
        let predicate = todayPredicate()

        let query = HKAnchoredObjectQuery(type: type, predicate: predicate, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] _, samples, _, _, _ in
            guard let value = Self.latestValue(from: samples, unit: unit) else { return }
            Task { @MainActor in self?.liveHeartRate = value }
        }
        query.updateHandler = { [weak self] _, samples, _, _, _ in
            guard let value = Self.latestValue(from: samples, unit: unit) else { return }
            Task { @MainActor in self?.liveHeartRate = value }
        }
        store.execute(query)
        heartRateQuery = query
    }

    private func startStepsQuery() {
        let type = HKQuantityType(.stepCount)
        let unit = HKUnit.count()
        let predicate = todayPredicate()
        let accumulator = stepsAccumulator

        let query = HKAnchoredObjectQuery(type: type, predicate: predicate, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] _, samples, _, _, _ in
            let batchSum = Self.sumValues(from: samples, unit: unit)
            Task { @MainActor in
                let total = await accumulator.add(batchSum)
                self?.liveSteps = total
            }
        }
        query.updateHandler = { [weak self] _, samples, _, _, _ in
            let batchSum = Self.sumValues(from: samples, unit: unit)
            Task { @MainActor in
                let total = await accumulator.add(batchSum)
                self?.liveSteps = total
            }
        }
        store.execute(query)
        stepsQuery = query
    }

    private func startEnergyQuery() {
        let type = HKQuantityType(.activeEnergyBurned)
        let unit = HKUnit.kilocalorie()
        let predicate = todayPredicate()
        let accumulator = energyAccumulator

        let query = HKAnchoredObjectQuery(type: type, predicate: predicate, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] _, samples, _, _, _ in
            let batchSum = Self.sumValues(from: samples, unit: unit)
            Task { @MainActor in
                let total = await accumulator.add(batchSum)
                self?.liveActiveEnergy = total
            }
        }
        query.updateHandler = { [weak self] _, samples, _, _, _ in
            let batchSum = Self.sumValues(from: samples, unit: unit)
            Task { @MainActor in
                let total = await accumulator.add(batchSum)
                self?.liveActiveEnergy = total
            }
        }
        store.execute(query)
        energyQuery = query
    }

    private func todayPredicate() -> NSPredicate {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        return HKQuery.predicateForSamples(withStart: startOfDay, end: nil, options: .strictStartDate)
    }

    nonisolated private static func latestValue(from samples: [HKSample]?, unit: HKUnit) -> Double? {
        (samples as? [HKQuantitySample])?.last?.quantity.doubleValue(for: unit)
    }

    nonisolated private static func sumValues(from samples: [HKSample]?, unit: HKUnit) -> Double {
        (samples as? [HKQuantitySample])?.reduce(0) { $0 + $1.quantity.doubleValue(for: unit) } ?? 0
    }
}

private actor Accumulator {
    private var total: Double = 0

    func add(_ value: Double) -> Double {
        total += value
        return total
    }
}
