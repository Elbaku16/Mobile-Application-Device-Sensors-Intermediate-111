//
//  TodayDashboardView.swift
//  TrailMarkLenin
//
//  Created by Lenin Baku Cortez Hernandez on 11/08/26.
//

import SwiftUI
import TrailmarkCore

struct TodayDashboardView: View {
    @State private var healthManager = HealthKitManager()

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Today")
                .task {
                    await healthManager.requestAuthorization()
                }
                .refreshable {
                    await healthManager.refreshToday()
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if healthManager.authorizationDenied {
            ContentUnavailableView(
                "Health Access Needed",
                systemImage: "heart.slash",
                description: Text("Enable Health access in Settings to see your activity.")
            )
        } else if let summary = healthManager.todaySummary {
            List {
                metricRow(title: "Steps", value: "\(Int(summary.steps))", icon: "figure.walk")
                metricRow(title: "Distance", value: String(format: "%.2f km", summary.distanceMeters / 1000), icon: "map")
                metricRow(title: "Active Energy", value: "\(Int(summary.activeEnergyKcal)) kcal", icon: "flame")
            }
        } else if healthManager.isLoading {
            ProgressView("Loading your activity…")
        } else {
            ContentUnavailableView(
                "No Data Yet",
                systemImage: "chart.bar",
                description: Text("Pull to refresh once you've granted access.")
            )
        }
    }

    private func metricRow(title: String, value: String, icon: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
            Spacer()
            Text(value).bold()
        }
    }
}
