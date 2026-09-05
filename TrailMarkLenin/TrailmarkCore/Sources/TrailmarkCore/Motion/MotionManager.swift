//
//  MotionManager.swift
//  TrailmarkCore
//
//  Created by Lenin Baku Cortez Hernandez on 22/08/26.
//

import Foundation
import CoreMotion
import Observation

@MainActor
@Observable
public final class MotionManager {
    public private(set) var pitch: Double = 0
    public private(set) var roll: Double = 0
    public private(set) var isActive: Bool = false

    private let motionManager = CMMotionManager()

    public init() {}

    public var isMotionAvailable: Bool {
        motionManager.isDeviceMotionAvailable
    }

    public func startTracking() {
        guard isMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 0.2
        isActive = true

        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let data else { return }
            self?.pitch = data.attitude.pitch
            self?.roll = data.attitude.roll
        }
    }

    public func stopTracking() {
        motionManager.stopDeviceMotionUpdates()
        isActive = false
    }
}
