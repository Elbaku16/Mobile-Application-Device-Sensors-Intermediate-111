//
//  VideoPicker.swift
//  TrailMarkLenin
//
//  Created by Lenin Baku Cortez Hernandez on 13/08/26.
//

//
//  VideoPicker.swift
//  TrailMarkLenin
//

import SwiftUI
import UIKit

struct VideoPicker: UIViewControllerRepresentable {
    var onPicked: (URL) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.mediaTypes = ["public.movie"]

        let canRecordVideo = UIImagePickerController.isSourceTypeAvailable(.camera)
            && UIImagePickerController.isCameraDeviceAvailable(.rear)
            && (UIImagePickerController.availableMediaTypes(for: .camera)?.contains("public.movie") ?? false)

        if canRecordVideo {
            picker.sourceType = .camera
            picker.cameraCaptureMode = .video
        } else {
            picker.sourceType = .photoLibrary
        }

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPicked: onPicked)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onPicked: (URL) -> Void

        init(onPicked: @escaping (URL) -> Void) {
            self.onPicked = onPicked
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            picker.dismiss(animated: true)
            if let url = info[.mediaURL] as? URL {
                onPicked(url)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
