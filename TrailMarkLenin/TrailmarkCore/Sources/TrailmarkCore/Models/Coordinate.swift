//
//  Coordinate.swift
//  TrailmarkCore
//
//  Created by Lenin Baku Cortez Hernandez on 15/08/26.
//

import Foundation
import CoreLocation

public struct Coordinate: Codable, Sendable, Equatable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    public init(_ clCoordinate: CLLocationCoordinate2D) {
        self.latitude = clCoordinate.latitude
        self.longitude = clCoordinate.longitude
    }

    public var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
