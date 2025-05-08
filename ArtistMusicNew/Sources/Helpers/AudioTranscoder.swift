//
//  AudioTranscoder.swift
//  ArtistMusic
//
//  Created by Theo Battaglia on 5/5/25.
//


//
//  AudioTranscoder.swift
//  ArtistMusic
//
//  Converts unsupported audio to m4a (AAC) when needed.
//  If the source is already decodable by AVFoundation,
//  it simply copies the file.
//

import Foundation
import AVFoundation

enum AudioTranscoder {

    /// Guarantees a local file: copies `src` to `destinationDir`
    /// and *optionally* transcodes in-place to `.m4a`.
    static func ensurePlayableCopy(of src: URL,
                                   in destinationDir: URL) -> URL? {

        let dest = destinationDir.appendingPathComponent(src.lastPathComponent)

        // Copy the original no matter what
        do {
            try FileManager.default.removeItem(at: dest)   // discard old
        } catch { /* ignore */ }
        do {
            try FileManager.default.copyItem(at: src, to: dest)
            print("📂 Copied to", dest.lastPathComponent)
        } catch {
            print("copy error:", error); return nil
        }

        // If AVFoundation can read it, we're done.
        if AVURLAsset(url: dest).isPlayable { return dest }

        // Otherwise fire a background transcode; UI doesn’t block.
        DispatchQueue.global(qos: .utility).async {
            let asset = AVURLAsset(url: dest)
            guard let export = AVAssetExportSession(asset: asset,
                                                    presetName: AVAssetExportPresetAppleM4A)
            else { return }
            let m4aURL = dest.deletingPathExtension().appendingPathExtension("m4a")
            export.outputURL = m4aURL
            export.outputFileType = .m4a
            export.exportAsynchronously {
                if export.status == .completed {
                    try? FileManager.default.removeItem(at: dest)
                    print("🔀 Transcoded →", m4aURL.lastPathComponent)
                } else if let e = export.error {
                    print("transcode failed:", e.localizedDescription)
                }
            }
        }
        return dest           // UI can already use the copied file
    }
}

