import SwiftUI

@main
struct ArtistMusicApp: App {
    // One shared instance of each ObservableObject
    @StateObject private var store = ArtistStore()
    @StateObject private var player = AudioPlayer()

    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .bottom) {
                // Main content
                ArtistCarouselView()
                    .environmentObject(store)  // inject ArtistStore
                    .environmentObject(player) // inject AudioPlayer
                
                // Now playing bar always at the bottom
                if player.current != nil {
                    NowPlayingBar()
                        .environmentObject(player)
                        .zIndex(100) // Keep it on top
                }
            }
        }
    }
}
