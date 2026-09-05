//
//  WristHomeView.swift
//  TrailMarkLenin
//
//  Created by Lenin Baku Cortez Hernandez on 22/08/26.
//

//
//  WristHomeView.swift
//  TrailMarkLenin Watch App Watch App
//
//  Created by Lenin Baku Cortez Hernandez on 22/08/26.
//

import SwiftUI
import TrailmarkCore

struct WristHomeView: View {
    @State private var healthManager = HealthKitManager()
    @State private var recoveryManager = RecoveryManager()
    @State private var showSavedConfirmation = false

    var body: some View {
        VStack(spacing: 8) {
            Text("\(Int(healthManager.todaySummary?.activeEnergyKcal ?? 0))")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)
            Text("kcal today")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer(minLength: 4)

            Button {
                Task {
                    let success = await recoveryManager.saveSampleWorkout()
                    showSavedConfirmation = success
                }
            } label: {
                Label("Log Workout", systemImage: "figure.walk.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)

            if showSavedConfirmation {
                Text("Saved!")
                    .font(.caption2)
                    .foregroundStyle(.green)
            }
        }
        .padding(.horizontal, 4)
        .task {
            await healthManager.requestAuthorization()
            await recoveryManager.requestAuthorization()
        }
    }
}
