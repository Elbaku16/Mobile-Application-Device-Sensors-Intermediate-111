//
//  RecoveryView.swift
//  TrailMarkLenin
//
//  Created by Lenin Baku Cortez Hernandez on 15/08/26.


import SwiftUI
import Charts
import TrailmarkCore

struct RecoveryView: View {
    @State private var manager = RecoveryManager()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    sleepSection
                    chartSection
                    workoutSection
                }
                .padding()
            }
            .navigationTitle("Recovery")
            .task {
                await manager.requestAuthorization()
            }
            .refreshable {
                await manager.loadRecoveryData()
            }
        }
    }

    private var sleepSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last Night's Sleep")
                .font(.headline)
            if let duration = manager.lastNightSleepDuration {
                Text(formattedDuration(duration))
                    .font(.system(size: 34, weight: .bold))
            } else {
                Text("No sleep data found")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Active Energy — Last 7 Days")
                .font(.headline)
            Chart(manager.weeklyEnergy) { day in
                BarMark(
                    x: .value("Day", day.date, unit: .day),
                    y: .value("kcal", day.kcal)
                )
            }
            .frame(height: 180)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var workoutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                Task {
                    let success = await manager.saveSampleWorkout()
                    print("Workout saved: \(success)")
                }
            } label: {
                Label("Save Sample Workout", systemImage: "figure.walk.circle.fill")
                    .font(.title3)
            }
            .buttonStyle(.borderedProminent)

            if manager.workoutSaved {
                Label("Saved to Health", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
    }

    private func formattedDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}
