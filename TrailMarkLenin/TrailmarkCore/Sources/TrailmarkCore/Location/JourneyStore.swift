//
//  JourneyStore.swift
//  TrailmarkCore
//
//  Created by Lenin Baku Cortez Hernandez on 15/08/26.
//

import Foundation
import Observation

@MainActor
@Observable
public final class JourneyStore {
    public private(set) var journeys: [Journey] = []

    private let fileManager = FileManager.default
    private let indexFileName = "journeys_index.json"

    private var indexURL: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(indexFileName)
    }

    public init() {
        loadIndex()
    }

    @discardableResult
    public func startJourney() -> Journey {
        let journey = Journey()
        journeys.insert(journey, at: 0)
        saveIndex()
        return journey
    }

    public func endJourney(id: UUID, route: [Coordinate]) {
        guard let index = journeys.firstIndex(where: { $0.id == id }) else { return }
        journeys[index].endDate = Date()
        journeys[index].route = route
        saveIndex()
    }

    public func attachMemo(_ memoID: UUID, toJourney journeyID: UUID) {
        guard let index = journeys.firstIndex(where: { $0.id == journeyID }) else { return }
        journeys[index].memoIDs.append(memoID)
        saveIndex()
    }

    public func delete(_ journey: Journey) {
        journeys.removeAll { $0.id == journey.id }
        saveIndex()
    }

    private func loadIndex() {
        guard let data = try? Data(contentsOf: indexURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([Journey].self, from: data) {
            journeys = decoded.sorted { $0.startDate > $1.startDate }
        }
    }

    private func saveIndex() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(journeys) {
            try? data.write(to: indexURL, options: .atomic)
        }
    }
}
