//
//  MotionView.swift
//  TrailMarkLenin
//
//  Created by Lenin Baku Cortez Hernandez on 22/08/26.
//

import SwiftUI
import TrailmarkCore

struct MotionView: View {
    @State private var motionManager = MotionManager()

    var body: some View {
        VStack(spacing: 6) {
            Text("Wrist Tilt")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(String(format: "%.1f°", motionManager.pitch * 180 / .pi))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .contentTransition(.numericText())

            if !motionManager.isMotionAvailable {
                Text("Motion not available")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 4)
        .onAppear {
            motionManager.startTracking()
        }
        .onDisappear {
            motionManager.stopTracking()
        }
    }
}
