//
//  AudioPlayer.swift
//  ArtistMusic
//
//  Created by Theo Battaglia on 5/5/25.
//

import Foundation
import AVFoundation
import Combine

/// Lightweight wrapper around `AVPlayer` that exposes Combine-friendly
/// playback state for SwiftUI.
final class AudioPlayer: ObservableObject {

    // ───────── Published to UI
    @Published var current:   Song?
    @Published var progress:  Double = 0     // 0 … 1
    @Published var isPlaying: Bool   = false
    @Published var rotation:  Double = 0     // 0 … 360 (for disc spin)

    // ───────── Internals
    private let player = AVPlayer()
    private var queue: [Song] = []
    private var timeObserver: Any?
    private var statusCancellable: AnyCancellable?
    private var spinTimer: Timer?

    // MARK: init -----------------------------------------------------------
    init() {

        // 1. Activate a simple playback session (speaks even with mute on)
        do {
            let s = AVAudioSession.sharedInstance()
            try s.setCategory(.playback, mode: .default)
            try s.setActive(true)
        } catch {
            print("⚠️ AVAudioSession error:", error)
        }

        // 2. Periodically publish progress
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.25, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard
                let self,
                let dur = self.player.currentItem?.duration.seconds,
                dur.isFinite, dur > 0
            else { return }
            self.progress = time.seconds / dur
        }
    }

    deinit {
        if let o = timeObserver { player.removeTimeObserver(o) }
        spinTimer?.invalidate()
    }

    // MARK: Queue control --------------------------------------------------
    func enqueue(_ songs: [Song], startAt index: Int = 0) {
        queue = songs
        guard queue.indices.contains(index) else { return }
        playSong(queue[index])
    }

    func playSong(_ song: Song) {

        // ── unwrap URL ────────────────────────────────────────────────
        guard let url = song.fileURL else {
            print("‼️ fileURL == nil for", song.title)
            return
        }

        // optional diagnostic: show size
        if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
            print("   file size:", size, "bytes")
        }

        // ── prepare AVPlayerItem ──────────────────────────────────────
        let item = AVPlayerItem(url: url)

        statusCancellable = item
            .publisher(for: \.status, options: .initial)
            .sink { [weak self] status in
                switch status {
                case .failed:
                    print("🛑 AVPlayerItem error:", item.error ?? "nil")
                case .readyToPlay:
                    print("▶️ ready, starting", url.lastPathComponent)
                    self?.player.play()
                default: break
                }
            }

        player.replaceCurrentItem(with: item)
        current    = song
        isPlaying  = true
        startRotation()
    }
    
    // Add seeking functionality for the interactive progress bar
    // Public method for seeking to a percentage position in the current track
    // Public method for seeking to a percentage position in the current track
    // Add seeking functionality for interactive progress bar
    func seekToPercentage(_ percentage: Double) {
        guard let duration = player.currentItem?.duration,
              duration.seconds.isFinite, duration.seconds > 0 else { return }
        
        let time = CMTime(seconds: duration.seconds * percentage, preferredTimescale: 600)
        print("Seeking to: \(percentage * 100)% (\(time.seconds) seconds)")
        player.seek(to: time)
    }

    // MARK: Simple transport ----------------------------------------------
    func play()    { player.play();  isPlaying = true;  startRotation() }
    func pause()   { player.pause(); isPlaying = false }
    func toggle()  { isPlaying ? pause() : play() }

    func next() {
        guard
            let cur = current,
            let idx = queue.firstIndex(of: cur),
            queue.indices.contains(idx + 1)
        else { return }
        playSong(queue[idx + 1])
    }

    func previous() {
        guard
            let cur = current,
            let idx = queue.firstIndex(of: cur),
            queue.indices.contains(idx - 1)
        else { return }
        playSong(queue[idx - 1])
    }

    // MARK: Disc rotation timer -------------------------------------------
    func startRotation() {
        guard spinTimer == nil else { return }
        spinTimer = Timer.scheduledTimer(withTimeInterval: 0.02,
                                         repeats: true) { [weak self] _ in
            guard let self, self.isPlaying else { return }
            rotation = (rotation + 0.4).truncatingRemainder(dividingBy: 360)
        }
    }
}
