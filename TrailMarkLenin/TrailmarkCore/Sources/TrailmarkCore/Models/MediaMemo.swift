//
//  MediaMemo.swift
//  TrailmarkCore
//
//  Created by Lenin Baku Cortez Hernandez on 13/08/26.
//

import Foundation

public enum MemoType: String, Codable, Sendable {
    case audio
    case video
}

public struct MediaMemo: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let type: MemoType
    public let date: Date
    public let duration: TimeInterval
    public let fileName: String
    public var location: Coordinate?
    public var journeyID: UUID?

    public init(id: UUID = UUID(), type: MemoType, date: Date = Date(), duration: TimeInterval, fileName: String, location: Coordinate? = nil, journeyID: UUID? = nil) {
        self.id = id
        self.type = type
        self.date = date
        self.duration = duration
        self.fileName = fileName
        self.location = location
        self.journeyID = journeyID
    }
}
