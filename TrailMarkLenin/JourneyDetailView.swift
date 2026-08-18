//
//  JourneyDetailView.swift
//  TrailMarkLenin
//
//  Created by Lenin Baku Cortez Hernandez on 15/08/26.
//

import SwiftUI
import MapKit
import TrailmarkCore

struct JourneyDetailView: View {
    let journey: Journey
    let journeyStore: JourneyStore

    @State private var healthManager = HealthKitManager()
    @State private var mediaStore = MediaStore()
    @State private var energyKcal: Double = 0
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                mapSection
                healthSection
                memosSection
            }
            .padding()
        }
        .navigationTitle("Journey")
        .task {
            await loadHealthSummary()
        }
    }

    private var mapSection: some View {
        Map(position: $cameraPosition) {
            if journey.route.count > 1 {
                MapPolyline(coordinates: journey.route.map { $0.clCoordinate })
                    .stroke(.blue, lineWidth: 4)
            }
            ForEach(journeyMemos) { memo in
                if let location = memo.location {
                    Marker(memo.type == .video ? "Video" : "Audio", coordinate: location.clCoordinate)
                }
            }
        }
        .frame(height: 250)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            if journey.route.isEmpty {
                ContentUnavailableView("No Route Recorded", systemImage: "location.slash")
                    .background(.thinMaterial)
            }
        }
    }

    private var healthSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Activity Summary")
                .font(.headline)
            Label("\(Int(energyKcal)) kcal active energy", systemImage: "flame.fill")
            if let end = journey.endDate {
                Label(durationText(from: journey.startDate, to: end), systemImage: "clock.fill")
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var memosSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Memos on this journey")
                .font(.headline)
            if journeyMemos.isEmpty {
                Text("No memos captured during this journey.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(journeyMemos) { memo in
                    Label(memo.type == .video ? "Video Memo" : "Audio Memo", systemImage: memo.type == .video ? "video.fill" : "waveform")
                }
            }
        }
    }

    private var journeyMemos: [MediaMemo] {
        mediaStore.memos.filter { journey.memoIDs.contains($0.id) }
    }

    private func loadHealthSummary() async {
        let end = journey.endDate ?? Date()
        energyKcal = await healthManager.activeEnergy(from: journey.startDate, to: end)
    }

    private func durationText(from start: Date, to end: Date) -> String {
        let minutes = Int(end.timeIntervalSince(start)) / 60
        return "\(minutes) min"
    }
}
