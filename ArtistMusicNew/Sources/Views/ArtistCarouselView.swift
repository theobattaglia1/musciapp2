import SwiftUI

/// Swipe left / right to move through full-screen ArtistDetailView pages.
struct ArtistCarouselView: View {
    
    @EnvironmentObject private var store: ArtistStore     // all artists
    
    var body: some View {
        TabView {
            ForEach(store.artists) { artist in
                ArtistDetailView(artistID: artist.id)
                    .tag(artist.id)                       // keeps paging stable
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea(edges: .top)                     // banner bleeds into status bar
        
    }
}



#if DEBUG
#Preview {
    ArtistCarouselView()
        .environmentObject(ArtistStore())   // demo data
        .environmentObject(AudioPlayer())   // bar needs the player in previews
}
#endif
