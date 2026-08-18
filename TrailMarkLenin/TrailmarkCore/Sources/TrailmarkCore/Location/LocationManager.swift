//
//  LocationManager.swift
//  TrailmarkCore
//
//  Created by Lenin Baku Cortez Hernandez on 15/08/26.
//

import Foundation
import CoreLocation
import Observation

@MainActor
@Observable
public final class LocationManager: NSObject {
    public private(set) var currentCoordinate: Coordinate?
    public private(set) var isTracking = false
    public private(set) var permissionDenied = false
    public private(set) var recordedRoute: [Coordinate] = []

    private let manager = CLLocationManager()

    public override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    public func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    public func startTracking() {
        recordedRoute = []
        isTracking = true
        manager.startUpdatingLocation()
    }

    public func stopTracking() -> [Coordinate] {
        isTracking = false
        manager.stopUpdatingLocation()
        return recordedRoute
    }
}

extension LocationManager: CLLocationManagerDelegate {
    public nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            switch status {
            case .denied, .restricted:
                self.permissionDenied = true
            case .authorizedWhenInUse, .authorizedAlways:
                self.permissionDenied = false
            default:
                break
            }
        }
    }

    public nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        let coordinate = Coordinate(latest.coordinate)
        Task { @MainActor in
            self.currentCoordinate = coordinate
            if self.isTracking {
                self.recordedRoute.append(coordinate)
            }
        }
    }
}
