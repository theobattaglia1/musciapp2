//
//  EditArtistSheet.swift
//  ArtistMusic
//
//  Created by Theo Battaglia on 5/5/25.
//


import SwiftUI

/// One stop for: rename, replace banner / avatar, crop.
/// All edits are applied immediately via ArtistStore mutators.
struct EditArtistSheet: View {

    @EnvironmentObject private var store: ArtistStore
    @Environment(\.dismiss)       private var dismiss

    let artistID: UUID
    @State private var draftName: String

    // pickers
    @State private var pickingBanner = false
    @State private var pickingAvatar = false

    init(artist: Artist) {
        artistID   = artist.id
        _draftName = State(initialValue: artist.name)
        _bannerImg = State(initialValue: artist.bannerData.flatMap(UIImage.init))
        _avatarImg = State(initialValue: artist.avatarData.flatMap(UIImage.init))
    }

    // local previews
    @State private var bannerImg: UIImage?
    @State private var avatarImg: UIImage?

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Artist", text: $draftName)
                }

                Section("Banner") {
                    HStack {
                        bannerPreview
                        Spacer()
                        Button("Change") { pickingBanner = true }
                    }
                }

                Section("Avatar") {
                    HStack {
                        avatarPreview
                        Spacer()
                        Button("Change") { pickingAvatar = true }
                    }
                }
            }
            .navigationTitle("Edit Artist")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveAndDismiss() }
                        .disabled(draftName.isEmpty)
                }
            }
            // pickers
            .sheet(isPresented: $pickingBanner) {
                ImagePicker(data: Binding(
                    get: { bannerImg?.pngData() },
                    set: { if let d = $0 { bannerImg = UIImage(data: d) } }))
            }
            .sheet(isPresented: $pickingAvatar) {
                ImagePicker(data: Binding(
                    get: { avatarImg?.pngData() },
                    set: { if let d = $0 { avatarImg = UIImage(data: d) } }))
            }
        }
    }

    // MARK: previews
    private var bannerPreview: some View {
        Group {
            if let ui = bannerImg {
                Image(uiImage: ui).resizable().scaledToFill()
            } else {
                Color.secondary.opacity(0.1)
                Image(systemName: "photo")
            }
        }
        .frame(width: 120, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var avatarPreview: some View {
        Group {
            if let ui = avatarImg {
                Image(uiImage: ui).resizable().scaledToFill()
            } else {
                Color.secondary.opacity(0.1)
                Image(systemName: "person")
            }
        }
        .frame(width: 60, height: 60)
        .clipShape(Circle())
    }

    // MARK: save
    private func saveAndDismiss() {
        store.updateName(draftName, for: artistID)
        store.setBanner(bannerImg?.pngData(), for: artistID)
        store.setAvatar(avatarImg?.pngData(), for: artistID)
        dismiss()
    }
}
