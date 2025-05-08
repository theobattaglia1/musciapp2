import Foundation
import Combine

@MainActor
public final class ArtistStore: ObservableObject {

    // Published collections
    @Published public private(set) var artists:   [Artist]   = []
    @Published public private(set) var playlists: [Playlist] = []
    @Published public private(set) var songs:     [Song]     = []

    // MARK: - Artist CRUD
    public func createArtist(name: String) {
        let newArtist = Artist(
            id: UUID(),
            name: name,
            headerImageData: nil,
            avatarImageData: nil
        )
        artists.append(newArtist)
    }

    // MARK: - Playlist CRUD
    public func createPlaylist(name: String, for artistID: UUID) {
        let newPlaylist = Playlist(
            id: UUID(),
            title: name,
            artistID: artistID,
            songIDs: []
        )
        playlists.append(newPlaylist)
    }

    // MARK: - Song CRUD
    public func createSong(title: String,
                           for artistID: UUID,
                           audioURL: URL? = nil,
                           duration: TimeInterval? = nil) {
        let newSong = Song(
            id: UUID(),
            title: title,
            artistID: artistID,
            audioURL: audioURL,
            duration: duration
        )
        songs.append(newSong)
    }

    // MARK: - Queries
    public func songs(for artistID: UUID) -> [Song] {
        songs.filter { $0.artistID == artistID }
    }

    public func playlists(for artistID: UUID) -> [Playlist] {
        playlists.filter { $0.artistID == artistID }
    }
}
