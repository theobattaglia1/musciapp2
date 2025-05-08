//
//  BatchEditSheet.swift
//  ArtistMusic
//
//  Created by Theo Battaglia on 5/5/25.
//


import SwiftUI
import UniformTypeIdentifiers

/// Batch-edit artwork / version / creators on many songs at once.
struct BatchEditSheet: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject     private var store: ArtistStore

    let artistID: UUID
    let songIDs: [UUID]                // targets

    // fields (empty = “leave unchanged”)
    @State private var newVersion  = ""
    @State private var newCreators = ""
    @State private var newArtwork: Data?

    @State private var showImagePicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Apply to all selected") {
                    TextField("New Version", text: $newVersion)
                    TextField("New Creators (comma-separated)",
                              text: $newCreators)
                }
                Section("Artwork") {
                    Button {
                        showImagePicker = true
                    } label: {
                        if let d = newArtwork, let ui = UIImage(data: d) {
                            Image(uiImage: ui).resizable().scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            Label("Choose Image", systemImage: "photo.on.rectangle")
                        }
                    }
                }
                Section {
                    Button("Delete Selected", role: .destructive) {
                        store.delete(songs: songIDs, for: artistID)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Batch Edit (\(songIDs.count))")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(newVersion.isEmpty &&
                                  newCreators.isEmpty &&
                                  newArtwork == nil)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(data: Binding(
                    get: { newArtwork },
                    set: { newArtwork = $0 }))
            }
        }
    }

    private func save() {
        store.batchUpdate(
            songIDs,
            for: artistID,
            newVersion:  newVersion.isEmpty  ? nil : newVersion,
            newCreators: newCreators.isEmpty ? nil :
                newCreators.split(separator: ",")
                           .map { $0.trimmingCharacters(in: .whitespaces) },
            newArtwork:  newArtwork
        )
        dismiss()
    }
}
