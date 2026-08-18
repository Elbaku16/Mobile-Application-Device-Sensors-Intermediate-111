//
//  TrailMarkLeninApp.swift
//  TrailMarkLenin
//
//  Created by Lenin Baku Cortez Hernandez on 15/08/26.
//


import SwiftUI
import TrailmarkCore

@main
struct TrailMarkLeninApp: App {
    // estos viven arriba de todo para que Journal y Journeys compartan
    // la misma sesión de tracking, el mismo store, y el mismo "activeJourneyID"
    @State private var locationManager = LocationManager()
    @State private var journeyStore = JourneyStore()
    @State private var activeJourneyID: UUID?

    var body: some Scene {
        WindowGroup {
            TabView {
                TodayDashboardView()
                    .tabItem { Label("Today", systemImage: "figure.walk") }
                MemoListView(locationManager: locationManager, journeyStore: journeyStore, activeJourneyID: activeJourneyID)
                    .tabItem { Label("Journal", systemImage: "mic.fill") }
                RecoveryView()
                    .tabItem { Label("Recovery", systemImage: "bed.double.fill") }
                JourneyListView(locationManager: locationManager, journeyStore: journeyStore, activeJourneyID: $activeJourneyID)
                    .tabItem { Label("Journeys", systemImage: "map.fill") }
            }
        }
    }
}
