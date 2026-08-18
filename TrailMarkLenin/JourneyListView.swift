//
//  JourneyListView.swift
//  TrailMarkLenin
//
//  Created by Lenin Baku Cortez Hernandez on 15/08/26.
//

import SwiftUI
import TrailmarkCore

struct JourneyListView: View {
    let locationManager: LocationManager
    let journeyStore: JourneyStore
    @Binding var activeJourneyID: UUID?

    var body: some View {
        NavigationStack {
            List {
                ForEach(journeyStore.journeys) { journey in
                    NavigationLink {
                        JourneyDetailView(journey: journey, journeyStore: journeyStore)
                    } label: {
                        JourneyRow(journey: journey)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        journeyStore.delete(journeyStore.journeys[index])
                    }
                }
            }
            .navigationTitle("Journeys")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        toggleTracking()
                    } label: {
                        Label(activeJourneyID == nil ? "Start" : "Stop",
                              systemImage: activeJourneyID == nil ? "location.circle.fill" : "stop.circle.fill")
                    }
                }
            }
            .overlay {
                if journeyStore.journeys.isEmpty {
                    ContentUnavailableView(
                        "No Journeys Yet",
                        systemImage: "map",
                        description: Text("Start tracking to log your first journey.")
                    )
                }
            }
            .task {
                locationManager.requestPermission()
            }
        }
    }

    private func toggleTracking() {
        if let id = activeJourneyID {
            let route = locationManager.stopTracking()
            journeyStore.endJourney(id: id, route: route)
            activeJourneyID = nil
        } else {
            let journey = journeyStore.startJourney()
            activeJourneyID = journey.id
            locationManager.startTracking()
        }
    }
}

private struct JourneyRow: View {
    let journey: Journey

    var body: some View {
        HStack {
            Image(systemName: "map.fill")
                .foregroundStyle(.blue)
            VStack(alignment: .leading) {
                Text(journey.startDate, style: .date)
                Text(journey.isActive ? "In progress" : "\(journey.route.count) points · \(journey.memoIDs.count) memos")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}
