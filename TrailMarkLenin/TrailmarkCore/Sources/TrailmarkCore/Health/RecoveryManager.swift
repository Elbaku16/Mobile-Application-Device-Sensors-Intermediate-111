//
//  RecoveryManager.swift
//  TrailmarkCore
//
//  Created by Lenin Baku Cortez Hernandez on 15/08/26.
//

//
//  RecoveryManager.swift
//  TrailmarkCore
//

import Foundation
import HealthKit
import Observation

@MainActor
@Observable
public final class RecoveryManager {
    public private(set) var lastNightSleepDuration: TimeInterval?
    public private(set) var weeklyEnergy: [DailyEnergy] = []
    public private(set) var workoutSaved = false
    public private(set) var isLoading = false

    private let store = HKHealthStore()

    public init() {}

    public func requestAuthorization() async {
        let shareTypes: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKQuantityType(.activeEnergyBurned)
        ]
        let readTypes: Set<HKObjectType> = [
            HKCategoryType(.sleepAnalysis),
            HKQuantityType(.activeEnergyBurned)
        ]
        do {
            try await store.requestAuthorization(toShare: shareTypes, read: readTypes)
        } catch {
            print("requestAuthorization failed: \(error)")
        }
        await loadRecoveryData()
    }

    public func loadRecoveryData() async {
        isLoading = true
        defer { isLoading = false }
        async let sleep = fetchLastNightSleep()
        async let energy = fetchWeeklyActiveEnergy()
        lastNightSleepDuration = await sleep
        weeklyEnergy = await energy
    }

    // MARK: - Save a sample workout

    @discardableResult
    public func saveSampleWorkout() async -> Bool {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .walking
        configuration.locationType = .outdoor

        let builder = HKWorkoutBuilder(healthStore: store, configuration: configuration, device: .local())

        let start = Date().addingTimeInterval(-30 * 60)
        let end = Date()

        do {
            try await builder.beginCollection(at: start)

            let energySample = HKQuantitySample(
                type: HKQuantityType(.activeEnergyBurned),
                quantity: HKQuantity(unit: .kilocalorie(), doubleValue: 150),
                start: start,
                end: end
            )
            try await builder.addSamples([energySample])
            try await builder.endCollection(at: end)
            _ = try await builder.finishWorkout()

            print("saveSampleWorkout succeeded")
            workoutSaved = true
            await loadRecoveryData()
            return true
        } catch {
            print("saveSampleWorkout failed: \(error)")
            workoutSaved = false
            return false
        }
    }

    // MARK: - Sleep

    /// "Last night" is bracketed as 6 PM yesterday through noon today.
    private func lastNightWindow() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .hour, value: -6, to: today) ?? today
        let end = calendar.date(byAdding: .hour, value: 12, to: today) ?? Date()
        return (start, end)
    }

    private func fetchLastNightSleep() async -> TimeInterval? {
        let (start, end) = lastNightWindow()
        let sleepType = HKCategoryType(.sleepAnalysis)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                let asleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue
                ]
                let total = (samples as? [HKCategorySample])?
                    .filter { asleepValues.contains($0.value) }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) } ?? 0
                continuation.resume(returning: total > 0 ? total : nil)
            }
            store.execute(query)
        }
    }

    // MARK: - Weekly active energy

    private func fetchWeeklyActiveEnergy() async -> [DailyEnergy] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var results: [DailyEnergy] = []

        for offset in stride(from: 6, through: 0, by: -1) {
            guard let dayStart = calendar.date(byAdding: .day, value: -offset, to: today),
                  let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { continue }
            let kcal = await sum(for: HKQuantityType(.activeEnergyBurned), unit: .kilocalorie(), start: dayStart, end: dayEnd) ?? 0
            results.append(DailyEnergy(date: dayStart, kcal: kcal))
        }
        return results
    }

    private func sum(for type: HKQuantityType, unit: HKUnit, start: Date, end: Date) async -> Double? {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, _ in
                continuation.resume(returning: statistics?.sumQuantity()?.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }
}
