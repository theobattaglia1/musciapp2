//  ImagePicker.swift
//  ArtistMusic
//
//  A minimal UIKit wrapper that lets the user
//  • pick or shoot a photo
//  • optionally edit (crop / zoom / rotate)
//  • returns JPEG or PNG `Data?` back to SwiftUI
//
//  Usage:
//      .sheet { ImagePicker(data: $avatarData) }

import SwiftUI
import PhotosUI
import UIKit

struct ImagePicker: UIViewControllerRepresentable {

    @Binding var data: Data?          // ← where the picked image ends up

    func makeCoordinator() -> Coord { Coord(self) }

    // MARK: UIViewControllerRepresentable
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let p = UIImagePickerController()
        p.sourceType      = .photoLibrary          // or .camera if you wish
        p.allowsEditing   = true                   // ← enables crop / zoom UI
        p.delegate        = context.coordinator
        return p
    }

    func updateUIViewController(_ ui: UIImagePickerController, context: Context) { }

    // MARK: – Coordinator
    final class Coord: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ p: ImagePicker) { self.parent = p }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

            // if user cropped → .editedImage, else .originalImage
            let uiImage = (info[.editedImage] ?? info[.originalImage]) as? UIImage
            parent.data = uiImage.flatMap { $0.jpegData(compressionQuality: 0.9) }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
