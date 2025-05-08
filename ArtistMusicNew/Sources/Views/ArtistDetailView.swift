import SwiftUI
import UniformTypeIdentifiers          // UTType.plainText for drag payloads

// ────────────────────────────────────────────────────────────
// MARK: – Artist page
// ────────────────────────────────────────────────────────────
struct ArtistDetailView: View {

    // Store + nav
    @EnvironmentObject private var store: ArtistStore
    @Environment(\.dismiss)       private var dismiss

    // UI state
    @State private var tab: Tab = .allSongs
    @State private var showEditArtist  = false
    @State private var showAddSong     = false
    @State private var showAddPlaylist = false
    @State private var songArtPicker  : UUID?
    @State private var collaboratorSheet: String?

    // Input
    let artistID: UUID
    private var artist: Artist? { store.artists.first { $0.id == artistID } }

    enum Tab: String, CaseIterable, Identifiable {
        case allSongs, playlists, collaborators
        var id: Self { self }
        var title: String { rawValue.capitalized }
    }

    // --------------------------------------------------------------------
    var body: some View {
        if let artist { content(for: artist) } else { missing }
    }

    // --------------------------------------------------------------------
    @ViewBuilder
    private func content(for artist: Artist) -> some View {

        VStack(spacing: 0) {

            Header(artist: artist) { showEditArtist = true }

            // ─── custom tab selector
            CustomTabBar(selectedTab: $tab)

            // ─── tab pages
            switch tab {

            case .allSongs:
                SongsList(artistID: artist.id,
                          onArtTap: { songArtPicker = $0 })

            case .playlists, .collaborators:
                ScrollView {
                    VStack(spacing: 0) {
                        if tab == .playlists {
                            PlaylistsList(artistID: artistID)
                        } else {
                            CollaboratorsList(artist: artist,
                                              onTap: { collaboratorSheet = $0 })
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { floatingPlus }

        // ─── sheets
        .sheet(isPresented: $showAddSong)      { AddSongSheet(artistID: artistID).environmentObject(store) }
        .sheet(isPresented: $showAddPlaylist)  { AddPlaylistSheet(artistID: artistID).environmentObject(store) }
        .sheet(item: $songArtPicker) { id in
            ImagePicker(data: Binding(
                get: { artist.songs.first { $0.id == id }?.artworkData },
                set: { store.setArtwork($0, for: id, artistID: artistID) }))
        }
        .sheet(item: $collaboratorSheet) { name in
            CollaboratorDetailView(name: name).environmentObject(store)
        }
        .sheet(isPresented: $showEditArtist) {
            EditArtistSheet(artist: artist).environmentObject(store)
        }
    }

    // --------------------------------------------------------------------
    private var floatingPlus: some View {
        HStack {
            Spacer()
            Button {
                tab == .playlists ? (showAddPlaylist = true)
                                  : (showAddSong     = true)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .bold))
                    .padding(22)
                    .background(.ultraThinMaterial, in: Circle())
                    .shadow(radius: 6)
            }
            .padding(.trailing, 28)
            .padding(.bottom, 220)          // clear Now-Playing bar
        }
    }

    // --------------------------------------------------------------------
    private var missing: some View {
        VStack {
            Spacer()
            Text("Artist not found").foregroundColor(.secondary)
            Spacer()
        }
        .onAppear { dismiss() }
    }
}

// ────────────────────────────────────────────────────────────
// MARK: Header
// ────────────────────────────────────────────────────────────
private struct Header: View {
    let artist: Artist
    let onEdit : () -> Void

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            banner.resizable()
                  .scaledToFill()
                  .frame(height: 260)
                  .clipped()

            HStack(spacing: 12) {
                avatar.resizable()
                      .scaledToFill()
                      .frame(width: 72, height: 72)
                      .clipShape(Circle())
                      .shadow(radius: 4)

                Text(artist.name)
                    .font(.title).bold()
                    .foregroundColor(.white)
                    .shadow(radius: 3)

                Image(systemName: "pencil")
                    .foregroundColor(.white)
                    .onTapGesture { onEdit() }
            }
            .padding([.leading, .bottom], 16)
        }
    }

    private var banner: Image {
        artist.bannerData.flatMap(UIImage.init(data:)).map(Image.init(uiImage:))
        ?? Image(systemName: "photo")
    }
    private var avatar: Image {
        artist.avatarData.flatMap(UIImage.init(data:)).map(Image.init(uiImage:))
        ?? Image(systemName: "person.circle")
    }
}

// ────────────────────────────────────────────────────────────
// MARK: SongsList  (live refresh, swipe, batch)
// ────────────────────────────────────────────────────────────
private struct SongsList: View {

    @EnvironmentObject private var store : ArtistStore
    @EnvironmentObject private var player: AudioPlayer

    let artistID: UUID
    let onArtTap: (UUID) -> Void

    @State private var selection  = Set<UUID>()
    @State private var editMode   : EditMode = .inactive
    @State private var batchSheet = false
    @State private var editSong   : Song?

    private var artist: Artist? { store.artists.first { $0.id == artistID } }

    var body: some View {
        if let artist {
            List(selection: $selection) {
                ForEach(artist.chronologicalSongs) { song in
                    row(for: song)
                }
                .onDelete { idx in
                    let ids = idx.map { artist.chronologicalSongs[$0].id }
                    store.delete(songs: ids, for: artist.id)
                }
            }
            .environment(\.editMode, $editMode)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if !selection.isEmpty { Button("Batch Edit") { batchSheet = true } }
                    EditButton()
                }
            }
            .sheet(isPresented: $batchSheet) {
                BatchEditSheet(artistID: artist.id,
                               songIDs: Array(selection))
                    .environmentObject(store)
                    .onDisappear { selection.removeAll() }
            }
            .sheet(item: $editSong) { s in
                EditSongSheet(artistID: artist.id, song: s)
                    .environmentObject(store)
            }
        }
    }
    
    @ViewBuilder
    private func row(for song: Song) -> some View {
        HStack {
            art(for: song)
                .onTapGesture { onArtTap(song.id) }

            VStack(alignment: .leading) {
                Text(song.title)
                Text(song.version)
                    .font(.caption).foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if editMode == .inactive { player.playSong(song) }
            }
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button("Edit") { editSong = song }
            
            // Add playlist menu
            Menu("Add to Playlist") {
                if let artist = artist {
                    ForEach(artist.playlists) { playlist in
                        if playlist.name != "All Songs" {
                            Button(playlist.name) {
                                print("📝 Adding song \(song.id) to playlist \(playlist.name) via menu")
                                store.add(songID: song.id, to: playlist.id, for: artistID)
                            }
                        }
                    }
                }
            }
        }
        .onDrag {
            // Use a more direct approach for the item provider
            let provider = NSItemProvider(object: song.id.uuidString as NSString)
            print("🎵 Dragging song: \(song.title) (ID: \(song.id))")
            return provider
        }
    }

   
    private func art(for song: Song) -> some View {
        Group {
            if let d = song.artworkData,
               let i = UIImage(data: d) {
                Image(uiImage: i).resizable().scaledToFill()
            } else {
                Image(systemName: "photo").resizable().scaledToFit()
                    .padding(10).foregroundColor(.secondary)
            }
        }
        .frame(width: 44, height: 44)
        .background(Color.secondary.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// ────────────────────────────────────────────────────────────
// MARK: PlaylistsList
// ────────────────────────────────────────────────────────────
private struct PlaylistsList: View {
    @EnvironmentObject private var store: ArtistStore
    @EnvironmentObject private var player: AudioPlayer
    @State private var selectedPlaylist: UUID?
    @State private var isEditMode = false
    @State private var selectedPlaylists = Set<UUID>()
    
    let artistID: UUID
    private let type = UTType.plainText
    
    private var artist: Artist? { store.artists.first { $0.id == artistID } }
    
    var body: some View {
        if let artist {
            VStack(spacing: 0) {
                // Header with count and edit button
                HStack {
                    Text("Playlists (\(artist.playlists.count))")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(isEditMode ? "Done" : "Edit") {
                        isEditMode.toggle()
                        if !isEditMode {
                            selectedPlaylists.removeAll()
                        }
                    }
                }
                .padding([.horizontal, .top])
                
                // Selection controls when in edit mode
                if isEditMode && !artist.playlists.isEmpty {
                    HStack {
                        Button(selectedPlaylists.count == artist.playlists.count ? "Deselect All" : "Select All") {
                            if selectedPlaylists.count == artist.playlists.count {
                                selectedPlaylists.removeAll()
                            } else {
                                selectedPlaylists = Set(artist.playlists.map { $0.id })
                            }
                        }
                        .foregroundColor(.accentColor)
                        
                        Spacer()
                        
                        if !selectedPlaylists.isEmpty {
                            Button(role: .destructive) {
                                // Delete selected playlists
                                for id in selectedPlaylists {
                                    // Skip All Songs playlist
                                    if let playlist = artist.playlists.first(where: { $0.id == id }),
                                       playlist.name != "All Songs" {
                                        // Need to implement this method in ArtistStore
                                        store.deletePlaylist(id, for: artistID)
                                    }
                                }
                                selectedPlaylists.removeAll()
                            } label: {
                                Text("Delete (\(selectedPlaylists.count))")
                            }
                            .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                
                // Playlist list
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(artist.playlists) { playlist in
                            EnhancedPlaylistRow(
                                playlist: playlist,
                                isEditMode: isEditMode,
                                isSelected: selectedPlaylists.contains(playlist.id),
                                onToggleSelection: {
                                    if selectedPlaylists.contains(playlist.id) {
                                        selectedPlaylists.remove(playlist.id)
                                    } else {
                                        selectedPlaylists.insert(playlist.id)
                                    }
                                },
                                onTap: {
                                    if isEditMode {
                                        // Toggle selection
                                        if selectedPlaylists.contains(playlist.id) {
                                            selectedPlaylists.remove(playlist.id)
                                        } else {
                                            selectedPlaylists.insert(playlist.id)
                                        }
                                    } else {
                                        // Open playlist
                                        selectedPlaylist = playlist.id
                                    }
                                },
                                onDrop: { songIDString in
                                    if let songID = UUID(uuidString: songIDString) {
                                        store.add(songID: songID, to: playlist.id, for: artistID)
                                        return true
                                    }
                                    return false
                                },
                                artistSongs: artist.songs
                            )
                        }
                    }
                }
                
                Spacer() // Push content to top
            }
            // To this (presenting as a full-screen cover instead of a sheet):
            .fullScreenCover(item: $selectedPlaylist) { playlistID in
                if let playlist = artist.playlists.first(where: { $0.id == playlistID }) {
                    ZStack(alignment: .top) {
                        PlaylistDetailSheet(artist: artist, playlist: playlist)
                            .environmentObject(store)
                            .environmentObject(player)
                            .padding(.bottom, player.current != nil ? 90 : 0) // Add space for player
                        
                        // Add now playing bar here
                        VStack {
                            Spacer()
                            if player.current != nil {
                                NowPlayingBar()
                                    .environmentObject(player)
                            }
                        }
                    }
                }
            }
        
        }
    }
}

// Enhanced playlist row with thumbnail and selection
private struct EnhancedPlaylistRow: View {
    let playlist: Playlist
    let isEditMode: Bool
    let isSelected: Bool
    let onToggleSelection: () -> Void
    let onTap: () -> Void
    let onDrop: (String) -> Bool
    let artistSongs: [Song]
    
    @State private var isTargeted = false
    private let type = UTType.plainText
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection checkbox when in edit mode
            if isEditMode {
                Button(action: onToggleSelection) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)
            }
            
            
            // Playlist artwork
            Group {
                if let artwork = playlist.artworkData, let image = UIImage(data: artwork) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    // Default artwork with music notes
                    ZStack {
                        Color.secondary.opacity(0.1)
                        Image(systemName: "music.note.list")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            
            VStack(alignment: .leading, spacing: 3) {
                Text(playlist.name)
                    .font(.body)
                    .lineLimit(1)
                
                Text("\(playlist.songIDs.count) \(playlist.songIDs.count == 1 ? "track" : "tracks")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Chevron when not in edit mode
            if !isEditMode {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(
            ZStack {
                Color.clear
                
                if isTargeted {
                    Color.accentColor.opacity(0.1)
                }
                
                if isSelected && isEditMode {
                    Color.accentColor.opacity(0.05)
                }
            }
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .onDrop(of: [type], isTargeted: $isTargeted) { providers in
            guard !isEditMode else { return false }
            
            for provider in providers {
                provider.loadObject(ofClass: NSString.self) { stringObj, error in
                    guard let stringObj = stringObj as? String else { return }
                    
                    DispatchQueue.main.async {
                        _ = onDrop(stringObj)
                    }
                }
                
                return true
            }
            
            return false
        }
        
        Divider()
            .padding(.leading, isEditMode ? 56 : 78)
    }
}

// Enhanced playlist detail view
// Enhanced playlist detail view
private struct PlaylistDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: ArtistStore
    @EnvironmentObject private var player: AudioPlayer
    
    @State private var isEditing = false
    @State private var showImagePicker = false
    @State private var editName = ""
    @State private var showRenameAlert = false
    
    let artist: Artist
    let playlist: Playlist
    
    var playlistSongs: [Song] {
        playlist.songIDs.compactMap { id in
            artist.songs.first { $0.id == id }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with playlist artwork and play button
                PlaylistHeaderView(
                    playlist: playlist,
                    artist: artist,
                    playlistSongs: playlistSongs,
                    onImageTap: { showImagePicker = true }
                )
                
                Divider()
                
                // Songs list
                List {
                    if !playlistSongs.isEmpty {
                        ForEach(playlistSongs) { song in
                            HStack {
                                songArtwork(for: song)
                                    .frame(width: 44, height: 44)
                                
                                VStack(alignment: .leading) {
                                    Text(song.title)
                                    Text(song.version)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                // Show remove button in edit mode
                                if isEditing {
                                    Button(action: {
                                        // Remove song from playlist
                                        removeTrackFromPlaylist(song.id)
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                player.playSong(song)
                            }
                        }
                        .onDelete { indices in
                            // Handle swipe-to-delete
                            let songsToRemove = indices.map { playlistSongs[$0].id }
                            for songID in songsToRemove {
                                removeTrackFromPlaylist(songID)
                            }
                        }
                    } else {
                        Text("No songs in this playlist")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                }
            }
            .navigationTitle(playlist.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(isEditing ? "Done" : "Edit") {
                        isEditing.toggle()
                    }
                }
                
                if isEditing {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button("Rename") {
                                editName = playlist.name
                                showRenameAlert = true
                            }
                            
                            Button("Set Cover Image", action: { showImagePicker = true })
                            
                            if playlist.name != "All Songs" {
                                Button("Delete Playlist", role: .destructive) {
                                    // Delete playlist
                                    store.deletePlaylist(playlist.id, for: artist.id)
                                    dismiss()
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                // Image picker for playlist artwork
                ImagePicker(data: Binding(
                    get: { playlist.artworkData },
                    set: { newData in
                        // Update playlist artwork
                        updateCoverArt(newData)
                    }
                ))
            }
            .alert("Rename Playlist", isPresented: $showRenameAlert) {
                TextField("Playlist Name", text: $editName)
                Button("Cancel", role: .cancel) { }
                Button("Save") {
                    if !editName.isEmpty {
                        updatePlaylistName(editName)
                    }
                }
            } message: {
                Text("Enter a new name for this playlist.")
            }
        }
    }
    
    // Helper functions with renamed methods to avoid ambiguity
    private func removeTrackFromPlaylist(_ songID: UUID) {
        store.removeSong(id: songID, from: playlist.id, for: artist.id)
    }
    
    private func updatePlaylistName(_ newName: String) {
        store.updatePlaylistName(playlist.id, newName: newName, for: artist.id)
    }
    
    private func updateCoverArt(_ data: Data?) {
        store.setPlaylistArtwork(data, for: playlist.id, artistID: artist.id)
    }
    
    private func songArtwork(for song: Song) -> some View {
        Group {
            if let data = song.artworkData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "music.note")
                    .resizable()
                    .scaledToFit()
                    .padding(10)
                    .foregroundColor(.secondary)
            }
        }
        .background(Color.secondary.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// Separate component for the playlist header with artwork and play button
private struct PlaylistHeaderView: View {
    let playlist: Playlist
    let artist: Artist
    let playlistSongs: [Song]
    let onImageTap: () -> Void
    
    @EnvironmentObject private var player: AudioPlayer
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 15) {
                // Playlist artwork
                Button(action: onImageTap) {
                    Group {
                        if let data = playlist.artworkData, let image = UIImage(data: data) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                        } else {
                            // Default image for playlists without artwork
                            ZStack {
                                Color.gray.opacity(0.2)
                                Image(systemName: "music.note.list")
                                    .font(.system(size: 30))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 0.5)
                    )
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    // Playlist info
                    Text(playlist.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(playlist.songIDs.count) songs")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Play button
                    if !playlistSongs.isEmpty {
                        Button(action: {
                            player.enqueue(playlistSongs)
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Play")
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                        }
                        .padding(.top, 5)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .background(Color.secondary.opacity(0.05))
    }
}
// ────────────────────────────────────────────────────────────
// MARK: CollaboratorsList
// ────────────────────────────────────────────────────────────
private struct CollaboratorsList: View {
    let artist: Artist
    let onTap : (String) -> Void

    var body: some View {
        let names = Array(Set(artist.songs.flatMap { $0.creators })).sorted()

        if names.isEmpty {
            EmptyState(icon: "person.3",
                       title: "No Collaborators",
                       message: "Add song credits to see collaborators.")
        } else {
            ForEach(names, id: \.self) { name in
                HStack {
                    Text(name)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 6)
                .contentShape(Rectangle())
                .onTapGesture { onTap(name) }
                Divider()
            }
        }
    }
}
// ────────────────────────────────────────────────────────────
// MARK: Custom Tab Components
// ────────────────────────────────────────────────────────────
// ────────────────────────────────────────────────────────────
// MARK: Custom Tab Components
// ────────────────────────────────────────────────────────────
private struct CustomTabBar: View {
    @Binding var selectedTab: ArtistDetailView.Tab
    
    var body: some View {
        ZStack(alignment: .top) {
            // Tab background
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(height: 56)
                .padding(.horizontal)
            
            // Tab buttons
            HStack(spacing: 0) {
                ForEach(ArtistDetailView.Tab.allCases) { tab in
                    TabButton(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        onTap: { selectedTab = tab }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.top, 8)
        .padding(.bottom, 12)
    }
}

private struct TabButton: View {
    let tab: ArtistDetailView.Tab
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Image(systemName: iconFor(tab))
                    .font(.system(size: isSelected ? 18 : 16))
                    .fontWeight(isSelected ? .semibold : .regular)
                
                Text(tab.title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1.5)
                            )
                            .shadow(color: Color.accentColor.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                }
            )
            .foregroundColor(isSelected ? .accentColor : .secondary)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func iconFor(_ tab: ArtistDetailView.Tab) -> String {
        switch tab {
        case .allSongs: return "music.note.list"
        case .playlists: return "rectangle.stack.fill"
        case .collaborators: return "person.2.fill"
        }
    }
}
// ────────────────────────────────────────────────────────────
// MARK: Empty-state helper
// ────────────────────────────────────────────────────────────
private struct EmptyState: View {
    let icon: String, title: String, message: String
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 40))
                .foregroundColor(.secondary)
            Text(title).font(.headline)
            Text(message).font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 80)
    }
}
