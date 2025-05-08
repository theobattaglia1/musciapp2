//
//  AddSongSheet.swift
//  ArtistMusic
//

import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

struct AddSongSheet: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject     private var store: ArtistStore

    let artistID: UUID

    // ───────── form fields
    @State private var title        = ""
    @State private var version      = "Master"
    @State private var creatorsText = ""
    @State private var notes        = ""
    @State private var artworkData: Data?

    // ───────── pickers
    @State private var showImporter      = false
    @State private var pickedURL: URL?
    @State private var showArtworkPicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Info") {
                    TextField("Title",   text: $title)
                    TextField("Version", text: $version)
                    TextField("Creators (comma-separated)",
                              text: $creatorsText)
                }

                Section("Artwork") {
                    Button { showArtworkPicker = true } label: {
                        if let data = artworkData,
                           let ui   = UIImage(data: data) {
                            Image(uiImage: ui)
                                .resizable().scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            Label("Choose Image", systemImage: "photo.on.rectangle")
                        }
                    }
                }

                Section("Audio file") {
                    if let pickedURL {
                        Text(pickedURL.lastPathComponent).lineLimit(2)
                    }
                    Button("Select File") { showImporter = true }
                }

                Section("Notes") {
                    TextEditor(text: $notes).frame(height: 80)
                }
            }
            .navigationTitle("Add Song")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(title.isEmpty || pickedURL == nil)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            // audio picker
            .fileImporter(isPresented: $showImporter,
                          allowedContentTypes: [.audio],
                          allowsMultipleSelection: false) { result in
                guard let url = try? result.get().first else { return }
                pickedURL = url
            }
            // artwork picker
            .sheet(isPresented: $showArtworkPicker) {
                ImagePicker(data: Binding(
                    get: { artworkData },
                    set: { artworkData = $0 }))
            }
        }
    }

    // MARK: save -----------------------------------------------------------
    private func save() {

        guard let src = pickedURL else { return }

        // security scope for Files / iCloud picks
        let scoped = src.startAccessingSecurityScopedResource()
        defer { if scoped { src.stopAccessingSecurityScopedResource() } }

        // destination dir: ~/Library/Application Support/ArtistMusic/Audio
        let support = FileManager.default.urls(for: .applicationSupportDirectory,
                                               in: .userDomainMask)[0]
        let audioDir = support.appendingPathComponent("ArtistMusic/Audio",
                                                      isDirectory: true)
        try? FileManager.default.createDirectory(at: audioDir,
                                                 withIntermediateDirectories: true)

        // copy or transcode
        guard let dest = AudioTranscoder.ensurePlayableCopy(of: src, in: audioDir) else {
            print("⛔️ ensurePlayableCopy returned nil for", src.lastPathComponent)
            return          // ← early-exit prevents store.add
        }

        // Song model
        let song = Song(
            id:        UUID(),
            title:     title,
            version:   version,
            creators:  creatorsText
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) },
            date:      Date(),
            notes:     notes,
            artworkData: artworkData,
            fileName:  dest.lastPathComponent
        )

        // append + persist  ← correct call
        store.add(song, to: artistID)

        dismiss()
    }
}
