//
//  EditSongSheet.swift
//  ArtistMusic
//
//  Created by Theo Battaglia on 5/5/25.
//


import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

/// Edit / delete one Song.  Pre-loads existing fields, lets the user
/// change metadata or artwork, or remove the track entirely.
struct EditSongSheet: View {

    @Environment(\.dismiss)        private var dismiss
    @EnvironmentObject             private var store: ArtistStore

    let artistID: UUID
    @State var song: Song          // mutable copy

    // pickers
    @State private var showArtwork = false
    @State private var showAudio   = false
    @State private var pickedURL: URL?

    var body: some View {
        NavigationStack {
            Form {
                Section("Info") {
                    TextField("Title",   text: $song.title)
                    TextField("Version", text: $song.version)
                    TextField("Creators (comma-separated)",
                              text: Binding(
                                get: { song.creators.joined(separator: ", ") },
                                set: { song.creators = $0.split(separator: ",")
                                                      .map { $0.trimmingCharacters(in: .whitespaces) } }))
                }

                Section("Artwork") {
                    Button { showArtwork = true } label: {
                        if let d = song.artworkData,
                           let ui = UIImage(data: d) {
                            Image(uiImage: ui)
                                .resizable().scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            Label("Choose Image", systemImage: "photo.on.rectangle")
                        }
                    }
                }

                Section("Replace audio") {
                    if let pickedURL {
                        Text(pickedURL.lastPathComponent).lineLimit(2)
                    }
                    Button("Select File") { showAudio = true }
                }

                Section("Notes") {
                    TextEditor(text: $song.notes).frame(height: 80)
                }

                Section {
                    Button("Delete Song", role: .destructive, action: deleteSong)
                }
            }
            .navigationTitle("Edit Song")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: saveChanges)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            // pickers
            .sheet(isPresented: $showArtwork) {
                ImagePicker(data: Binding(
                    get: { song.artworkData },
                    set: { song.artworkData = $0 }))
            }
            .fileImporter(isPresented: $showAudio,
                          allowedContentTypes: [.audio],
                          allowsMultipleSelection: false) { result in
                pickedURL = try? result.get().first
            }
        }
    }

    // ───────── actions
    private func saveChanges() {
        // handle optional new audio
        if let src = pickedURL {
            let support = FileManager.default
                .urls(for: .applicationSupportDirectory,
                      in: .userDomainMask)[0]
            let audioDir = support
                .appendingPathComponent("ArtistMusic/Audio", isDirectory: true)
            try? FileManager.default.createDirectory(at: audioDir,
                                                     withIntermediateDirectories: true)
            if let dest = AudioTranscoder.ensurePlayableCopy(of: src, in: audioDir) {
                song.fileName = dest.lastPathComponent
            }
        }
        store.update(song, for: artistID)
        dismiss()
    }

    private func deleteSong() {
        store.delete(songID: song.id, for: artistID)
        dismiss()
    }
}
