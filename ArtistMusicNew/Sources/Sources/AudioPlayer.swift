import Foundation
import Combine
import AVFoundation

@MainActor
final class AudioPlayer: ObservableObject {

    @Published private(set) var currentSong: Song?
    private var player: AVAudioPlayer?

    func play(song: Song) throws {
        currentSong = song
        guard let url = song.audioURL else { return }
        player = try AVAudioPlayer(contentsOf: url)
        player?.play()
    }

    func stop() {
        player?.stop()
        currentSong = nil
    }
}
