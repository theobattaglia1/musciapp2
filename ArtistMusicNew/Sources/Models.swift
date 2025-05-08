import Foundation

// MARK: - Song
struct Song: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var version: String
    var creators: [String]          // writers / producers
    var date: Date                  // creation date
    var notes: String
    var artworkData: Data?          // optional artwork image
    var fileName: String            // audio file stored in App Support

    init(id: UUID = UUID(),
         title: String,
         version: String,
         creators: [String],
         date: Date,
         notes: String,
         artworkData: Data?,
         fileName: String) {
        self.id = id
        self.title = title
        self.version = version
        self.creators = creators
        self.date = date
        self.notes = notes
        self.artworkData = artworkData
        self.fileName = fileName
    }
}

// MARK: - Playlist
struct Playlist: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var songIDs: [UUID]             // ordered list for drag-reorder
    var artworkData: Data?          // Optional playlist artwork
    var description: String?        // Optional playlist description

    init(id: UUID = UUID(),
         name: String,
         songIDs: [UUID] = [],
         artworkData: Data? = nil,
         description: String? = nil) {
        self.id = id
        self.name = name
        self.songIDs = songIDs
        self.artworkData = artworkData
        self.description = description
    }
}

// MARK: - Artist
struct Artist: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var bannerData: Data?           // header image
    var avatarData: Data?           // circular avatar
    var songs: [Song]
    var playlists: [Playlist]

    init(id: UUID = UUID(),
         name: String,
         bannerData: Data?,
         avatarData: Data?,
         songs: [Song] = [],
         playlists: [Playlist] = []) {
        self.id = id
        self.name = name
        self.bannerData = bannerData
        self.avatarData = avatarData
        self.songs = songs
        self.playlists = playlists
    }

    /// Helper: “All Songs” playlist computed from `songs`
    var chronologicalSongs: [Song] {
        songs.sorted { $0.date < $1.date }
    }
}
