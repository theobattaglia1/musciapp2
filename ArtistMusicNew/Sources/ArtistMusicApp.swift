import SwiftUI

@main
struct ArtistMusicApp: App {

    // One shared instance of each ObservableObject
    @StateObject private var store  = ArtistStore()
    @StateObject private var player = AudioPlayer()

    var body: some Scene {
        WindowGroup {
            ArtistCarouselView()          // root view
                .environmentObject(store)  // inject ArtistStore
                .environmentObject(player) // inject AudioPlayer
        }
    }
}
