//
//  MediaStore.swift
//  TrailmarkCore
//
//  Created by Lenin Baku Cortez Hernandez on 17/08/26.
//

import Foundation
import Observation

@MainActor
@Observable
public final class MediaStore {
    public private(set) var memos: [MediaMemo] = []

    private let fileManager = FileManager.default
    private let indexFileName = "memos_index.json"

    private var mediaDirectory: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Memos", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private var indexURL: URL {
        mediaDirectory.appendingPathComponent(indexFileName)
    }

    public init() {
        loadIndex()
    }

    // convierte el fileName relativo del memo en la URL completa de ahorita
    // (la carpeta de Documents cambia entre reinstalaciones, por eso nunca guardamos la ruta completa)
    public func fileURL(for memo: MediaMemo) -> URL {
        mediaDirectory.appendingPathComponent(memo.fileName)
    }

    @discardableResult
    public func saveMemo(data: Data, type: MemoType, duration: TimeInterval, fileExtension: String) -> MediaMemo? {
        let id = UUID()
        let fileName = "\(id.uuidString).\(fileExtension)"
        let destination = mediaDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: destination, options: .atomic)
        } catch {
            return nil
        }
        let memo = MediaMemo(id: id, type: type, duration: duration, fileName: fileName)
        memos.insert(memo, at: 0)
        saveIndex()
        return memo
    }

    public func delete(_ memo: MediaMemo) {
        // borramos el archivo real del disco primero, y luego la entrada del índice
        // así no dejamos "basura" huérfana aunque falle uno de los dos pasos
        try? fileManager.removeItem(at: fileURL(for: memo))
        memos.removeAll { $0.id == memo.id }
        saveIndex()
    }

    // actualiza la ubicación de un memo ya guardado (se usa justo después de grabarlo,
    // una vez que ya tenemos el memo y sabemos dónde estaba el usuario)
    public func updateLocation(_ location: Coordinate?, for memoID: UUID) {
        guard let index = memos.firstIndex(where: { $0.id == memoID }) else { return }
        memos[index].location = location
        saveIndex()
    }

    private func loadIndex() {
        guard let data = try? Data(contentsOf: indexURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([MediaMemo].self, from: data) {
            memos = decoded.sorted { $0.date > $1.date }
        }
    }

    private func saveIndex() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(memos) {
            try? data.write(to: indexURL, options: .atomic)
        }
    }
}
