//
//  CollaboratorDetailView.swift
//  ArtistMusic
//
//  Created by Theo Battaglia on 5/5/25.
//


import SwiftUI

/// Modal sheet: shows every song this collaborator touched, grouped by artist.
struct CollaboratorDetailView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject     private var store: ArtistStore

    let name: String

    private struct Entry: Identifiable {
        let id = UUID()
        let artist: String
        let song: Song
    }

    private var entries: [Entry] {
        store.artists.flatMap { artist in
            artist.songs.compactMap { song in
                song.creators.contains(where: { $0.caseInsensitiveCompare(name) == .orderedSame })
                ? Entry(artist: artist.name, song: song) : nil
            }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(Dictionary(grouping: entries, by: \.artist)
                            .sorted(by: { $0.key < $1.key }), id: \.key) { (artist, songs) in
                    Section(header: Text(artist)) {
                        ForEach(songs) { entry in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.song.title)
                                Text(entry.song.version)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }}
        }
    }
}
