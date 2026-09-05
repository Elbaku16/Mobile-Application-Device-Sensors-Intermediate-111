//
//  ContentView.swift
//  TrailMarkLenin Watch App Watch App
//
//  Created by Lenin Baku Cortez Hernandez on 22/08/26.
//

import SwiftUI
import TrailmarkCore

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 4) {
            Picker("", selection: $selectedTab) {
                Text("Home").tag(0)
                Text("Memo").tag(1)
                Text("Vitals").tag(2)
                Text("Motion").tag(3)
            }
            .pickerStyle(.navigationLink)
            .labelsHidden()

            switch selectedTab {
            case 0: WristHomeView()
            case 1: WristMemoView()
            case 2: LiveVitalsView()
            default: MotionView()
            }
        }
    }
}
