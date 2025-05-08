//  Sources/Helpers/Song+Helpers.swift
import Foundation

extension Song {
    /// “Writer · Producer” text the bar shows under the title.
    var artistLine: String {
        creators.joined(separator: " · ")
    }

    /// Where the audio file lives on disk.
    /// (Relies on `fileName` being set when you import the song.)
    var fileURL: URL? {
        let support = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return support
            .appendingPathComponent("ArtistMusic/Audio", isDirectory: true)
            .appendingPathComponent(fileName)         // ← fileName must not be ""
    }
}
