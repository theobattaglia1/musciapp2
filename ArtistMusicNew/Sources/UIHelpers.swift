//
//  EmptyState.swift
//  ArtistMusic
//
//  Created by Theo Battaglia on 5/5/25.
//


//
//  UIHelpers.swift
//  ArtistMusic
//
//  Small, reusable UI helpers shared across screens.
//

import SwiftUI


// ────────────────────────────────────────────────────────────
// MARK: Reusable “rename” sheet modifier (optional)
// ────────────────────────────────────────────────────────────
extension View {
    /// Presents a simple text-field sheet that calls `onSave`
    /// with the trimmed string when the user taps **Save**.
    func renameSheet(
        name: Binding<String>,
        isPresented: Binding<Bool>,
        onSave: @escaping (String) -> Void
    ) -> some View {
        sheet(isPresented: isPresented) {
            NavigationStack {
                Form { TextField("Name", text: name) }
                    .navigationTitle("Rename")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { isPresented.wrappedValue = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                onSave(name.wrappedValue.trimmingCharacters(in: .whitespaces))
                                isPresented.wrappedValue = false
                            }
                            .disabled(name.wrappedValue.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
            }
        }
    }
}
