//
//  AddPlaylistSheet.swift
//  ArtistMusic
//
//  Created by Theo Battaglia on 5/5/25.
//


import SwiftUI

/// Simple sheet to create a new empty playlist.
struct AddPlaylistSheet: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject     private var store: ArtistStore

    let artistID: UUID

    @State private var name: String = ""

    private var isSaveDisabled: Bool { name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Playlist Name", text: $name)
                        .autocapitalization(.words)
                }
            }
            .navigationTitle("New Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(isSaveDisabled)
                }
            }
        }
    }

    private func save() {
        print("👉 About to add playlist: \(name) for artist ID: \(artistID)")
        store.addPlaylist(name: name.trimmingCharacters(in: .whitespaces),
                          for: artistID)
        print("✅ Playlist added, dismissing sheet")
        dismiss()
    }
}
