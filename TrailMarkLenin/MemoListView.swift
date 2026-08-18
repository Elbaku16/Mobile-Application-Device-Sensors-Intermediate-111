//
//  MemoListView.swift
//  TrailMarkLenin
//
//  Created by Lenin Baku Cortez Hernandez on 13/08/26.
//

import SwiftUI
import AVFoundation
import TrailmarkCore

struct MemoListView: View {
    @State private var store = MediaStore()
    @State private var audioRecorder = AudioRecorderManager()
    @State private var showVideoPicker = false

    let locationManager: LocationManager
    let journeyStore: JourneyStore
    let activeJourneyID: UUID?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    ForEach(store.memos) { memo in
                        NavigationLink {
                            MemoDetailView(memo: memo, store: store)
                        } label: {
                            MemoRow(memo: memo, store: store)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            store.delete(store.memos[index])
                        }
                    }
                }
                .overlay {
                    if store.memos.isEmpty {
                        ContentUnavailableView(
                            "No Memos Yet",
                            systemImage: "mic.slash",
                            description: Text("Record audio or add a video to get started.")
                        )
                    }
                }

                // barra fija abajo con el botón de grabar, ya no usamos
                // toolbar bottomBar porque se perdía detrás del TabView
                Button {
                    Task { await toggleAudioRecording() }
                } label: {
                    Label(audioRecorder.isRecording ? "Stop Recording" : "Record Audio",
                          systemImage: audioRecorder.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(audioRecorder.isRecording ? .red : .blue)
                .padding()
            }
            .navigationTitle("Field Journal")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showVideoPicker = true
                    } label: {
                        Label("Video", systemImage: "video.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showVideoPicker) {
                VideoPicker { url in
                    Task { await saveVideo(from: url) }
                }
            }
        }
    }

    private func toggleAudioRecording() async {
        if audioRecorder.isRecording {
            if let result = audioRecorder.stopRecording() {
                saveAudio(from: result.url, duration: result.duration)
            }
        } else {
            await audioRecorder.startRecording()
        }
    }

    private func saveAudio(from tempURL: URL, duration: TimeInterval) {
        guard let data = try? Data(contentsOf: tempURL) else { return }
        let memo = store.saveMemo(data: data, type: .audio, duration: duration, fileExtension: "m4a")
        try? FileManager.default.removeItem(at: tempURL)
        attachGeotagAndJourney(to: memo)
    }

    private func saveVideo(from tempURL: URL) async {
        guard let data = try? Data(contentsOf: tempURL) else { return }
        let asset = AVURLAsset(url: tempURL)
        let duration = (try? await asset.load(.duration)).map { CMTimeGetSeconds($0) } ?? 0
        let memo = store.saveMemo(data: data, type: .video, duration: duration, fileExtension: "mov")
        attachGeotagAndJourney(to: memo)
    }

    private func attachGeotagAndJourney(to memo: MediaMemo?) {
        guard let memo else { return }
        store.updateLocation(locationManager.currentCoordinate, for: memo.id)
        if let journeyID = activeJourneyID {
            journeyStore.attachMemo(memo.id, toJourney: journeyID)
        }
    }
}

private struct MemoRow: View {
    let memo: MediaMemo
    let store: MediaStore
    @State private var thumbnail: UIImage?

    var body: some View {
        HStack {
            Group {
                if memo.type == .video, let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: memo.type == .video ? "video.fill" : "waveform")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 44, height: 44)
            .background(Color.gray.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading) {
                Text(memo.type == .video ? "Video Memo" : "Audio Memo")
                Text(memo.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
            if memo.location != nil {
                Image(systemName: "location.fill")
                    .font(.caption2)
                    .foregroundStyle(.blue)
            }
            Text(formattedDuration)
                .font(.caption)
                .monospacedDigit()
        }
        .task {
            if memo.type == .video {
                thumbnail = await generateThumbnail(for: store.fileURL(for: memo))
            }
        }
    }

    private var formattedDuration: String {
        let minutes = Int(memo.duration) / 60
        let seconds = Int(memo.duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func generateThumbnail(for url: URL) async -> UIImage? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        return try? await withCheckedThrowingContinuation { continuation in
            generator.generateCGImageAsynchronously(for: .zero) { cgImage, _, error in
                if let cgImage {
                    continuation.resume(returning: UIImage(cgImage: cgImage))
                } else {
                    continuation.resume(throwing: error ?? NSError(domain: "thumb", code: -1))
                }
            }
        }
    }
}
