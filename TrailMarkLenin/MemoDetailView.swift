//
//  MemoDetailView.swift
//  TrailMarkLenin
//
//  Created by Lenin Baku Cortez Hernandez on 13/08/26.
//

import SwiftUI
import AVKit
import TrailmarkCore

struct MemoDetailView: View {
    let memo: MediaMemo
    let store: MediaStore

    @State private var player: AVPlayer?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false

    var body: some View {
        VStack(spacing: 24) {
            if memo.type == .video, let player {
                VideoPlayer(player: player)
                    .frame(height: 300)
            } else {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)

                Button {
                    toggleAudioPlayback()
                } label: {
                    Label(isPlaying ? "Pause" : "Play", systemImage: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                }
                .buttonStyle(.borderedProminent)
            }

            Text(memo.date.formatted(date: .abbreviated, time: .shortened))
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle(memo.type == .video ? "Video Memo" : "Audio Memo")
        .onAppear { setUpPlayback() }
    }

    private func setUpPlayback() {
        let url = store.fileURL(for: memo)
        if memo.type == .video {
            player = AVPlayer(url: url)
        } else {
            audioPlayer = try? AVAudioPlayer(contentsOf: url)
        }
    }

    private func toggleAudioPlayback() {
        guard let audioPlayer else { return }
        if isPlaying {
            audioPlayer.pause()
        } else {
            audioPlayer.play()
        }
        isPlaying.toggle()
    }
}
