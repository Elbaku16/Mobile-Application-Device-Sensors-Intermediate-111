//
//  LiveVitalsView.swift
//  TrailMarkLenin
//
//  Created by Lenin Baku Cortez Hernandez on 22/08/26.
//

import SwiftUI
import TrailmarkCore
import HealthKit

struct LiveVitalsView: View {
    @State private var healthManager = HealthKitManager()

    var body: some View {
        VStack(spacing: 6) {
            metricRow(icon: "heart.fill", color: .red, value: heartRateText, unit: "BPM")
            metricRow(icon: "figure.walk", color: .green, value: stepsText, unit: "steps")
            metricRow(icon: "flame.fill", color: .orange, value: energyText, unit: "kcal")

            Button("Simulate Steps") {
                Task { await writeTestSteps() }
            }
            .font(.caption2)
            .padding(.top, 6)
        }
        .padding(.horizontal, 4)
        .task {
            await healthManager.requestAuthorization()
            healthManager.startLiveVitals()
        }
        .onDisappear {
            healthManager.stopLiveVitals()
        }
    }

    private func writeTestSteps() async {
        let store = HKHealthStore()
        let stepsType = HKQuantityType(.stepCount)

        do {
            try await store.requestAuthorization(toShare: [stepsType], read: [])
        } catch {
            print("Authorization for writing steps failed: \(error)")
        }

        let quantity = HKQuantity(unit: .count(), doubleValue: 50)
        let sample = HKQuantitySample(type: stepsType, quantity: quantity, start: Date(), end: Date())

        do {
            try await store.save(sample)
            print("Test steps saved successfully")
        } catch {
            print("writeTestSteps failed: \(error)")
        }
    }

    private var stepsText: String {
        let value = healthManager.liveSteps > 0 ? healthManager.liveSteps : (healthManager.todaySummary?.steps ?? 0)
        return "\(Int(value))"
    }

    private var energyText: String {
        let value = healthManager.liveActiveEnergy > 0 ? healthManager.liveActiveEnergy : (healthManager.todaySummary?.activeEnergyKcal ?? 0)
        return "\(Int(value))"
    }

    private var heartRateText: String {
        guard let hr = healthManager.liveHeartRate else { return "--" }
        return "\(Int(hr))"
    }

    private func metricRow(icon: String, color: Color, value: String, unit: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .contentTransition(.numericText())
            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
