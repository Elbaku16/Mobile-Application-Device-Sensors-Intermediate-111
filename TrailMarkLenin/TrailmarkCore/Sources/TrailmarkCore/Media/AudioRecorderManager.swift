//
//  AudioRecorderManager.swift
//  TrailmarkCore
//
//  Created by Lenin Baku Cortez Hernandez on 13/08/26.
//

import Foundation
import AVFoundation
import Observation

@MainActor
@Observable
public final class AudioRecorderManager: NSObject {
    public private(set) var isRecording = false
    public private(set) var permissionDenied = false

    private var recorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var startDate: Date?

    public override init() {
        super.init()
    }

    public func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    public func startRecording() async {
        let granted = await requestPermission()
        guard granted else {
            permissionDenied = true
            return
        }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            return
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]

        do {
            recorder = try AVAudioRecorder(url: tempURL, settings: settings)
            recorder?.record()
            recordingURL = tempURL
            startDate = Date()
            isRecording = true
        } catch {
            return
        }
    }

    @discardableResult
    public func stopRecording() -> (url: URL, duration: TimeInterval)? {
        recorder?.stop()
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false)

        guard let url = recordingURL, let start = startDate else { return nil }
        let duration = Date().timeIntervalSince(start)
        recordingURL = nil
        startDate = nil
        return (url, duration)
    }
}
