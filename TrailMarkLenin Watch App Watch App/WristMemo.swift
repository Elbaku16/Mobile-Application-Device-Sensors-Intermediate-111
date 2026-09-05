//
//  WristMemo.swift
//  TrailMarkLenin
//
//  Created by Lenin Baku Cortez Hernandez on 22/08/26.
//

import SwiftUI
import AVFoundation
import TrailmarkCore

struct WristMemoView: View {
    @State private var store = MediaStore()
    @State private var recorder = AudioRecorderManager()

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.memos) { memo in
                    NavigationLink {
                        WatchMemoDetailView(memo: memo, store: store)
                    } label: {
                        HStack {
                            Image(systemName: "waveform")
                            Text(memo.date, style: .time)
                            Spacer()
                            Text(formattedDuration(memo.duration))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .overlay {
                if store.memos.isEmpty {
                    ContentUnavailableView("No Memos", systemImage: "mic.slash")
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await toggleRecording() }
                    } label: {
                        Image(systemName: recorder.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                            .foregroundStyle(recorder.isRecording ? .red : .blue)
                    }
                }
            }
        }
    }

    private func toggleRecording() async {
        if recorder.isRecording {
            if let result = recorder.stopRecording() {
                guard let data = try? Data(contentsOf: result.url) else { return }
                store.saveMemo(data: data, type: .audio, duration: result.duration, fileExtension: "m4a")
                try? FileManager.default.removeItem(at: result.url)
            }
        } else {
            await recorder.startRecording()
        }
    }

    private func formattedDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

private struct WatchMemoDetailView: View {
    let memo: MediaMemo
    let store: MediaStore
    @State private var player: AVAudioPlayer?
    @State private var isPlaying = false

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(.blue)

            Button(isPlaying ? "Pause" : "Play") {
                togglePlayback()
            }
            .buttonStyle(.borderedProminent)
        }
        .onAppear {
            player = try? AVAudioPlayer(contentsOf: store.fileURL(for: memo))
        }
    }

    private func togglePlayback() {
        guard let player else { return }
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }
}
