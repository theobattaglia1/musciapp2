//  NowPlayingBar.swift
//  ArtistMusicNew
//  Updated 7 May 2025 – API modernisation & warning‑free build (iOS 17).
//
//  • Uses new two‑parameter `onChange` closure (no deprecated “perform”).
//  • Removes invalid `weak` capture – value‑type views are safe; we just
//    capture `[self]` to avoid retain‑cycle warnings.
//  • Drops Preview stub that referenced a non‑existent `AudioPlayer.preview`.
//
//  NOTE: Requires an `@ObservableObject` called `AudioPlayer` with the API
//  used below.

import SwiftUI
import AVFoundation

// MARK: – Compact bottom player bar
struct NowPlayingBar: View {
    @EnvironmentObject private var player: AudioPlayer

    // View‑state
    @State private var isDragging        = false
    @State private var dragProgress: Double = 0
    @State private var showSeekBar       = false
    @State private var autoHideWorkItem: DispatchWorkItem?

    // Layout constants
    private let artworkSize: CGFloat = 50
    private let barHeight:  CGFloat = 75

    var body: some View {
        if player.current != nil {
            ZStack(alignment: .bottom) {

                // ─────────────────────────── Seek bar
                if showSeekBar && player.isPlaying {
                    ElegantSeekBar(
                        progress: player.progress,
                        isDragging: $isDragging,
                        dragProgress: $dragProgress,
                        onSeek: { player.seekToPercentage($0) }
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, barHeight + 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .gesture(
                        DragGesture(minimumDistance: 20)
                            .onEnded { _ in hideSeekBar() }
                    )
                    .zIndex(110)
                    .onAppear { scheduleAutoHide() }
                    .onChange(of: isDragging) { _, nowDragging in
                        nowDragging ? cancelAutoHide() : scheduleAutoHide()
                    }
                }

                // ─────────────────────────── Main bar
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(radius: 4)
                    .frame(height: barHeight)
                    .overlay(playerOverlay)
                    .zIndex(100)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .animation(.easeInOut(duration: 0.2), value: player.isPlaying)
            .onAppear { player.startRotation() }
        }
    }

    // MARK: Overlay content
    private var playerOverlay: some View {
        HStack(spacing: 12) {
            Group {
                if let data = player.current?.artworkData, let img = UIImage(data: data) {
                    Image(uiImage: img).resizable().scaledToFill()
                } else {
                    Image(systemName: "music.note")
                        .resizable().scaledToFit().padding(12).foregroundColor(.secondary)
                }
            }
            .frame(width: artworkSize, height: artworkSize)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(radius: 2)
            .rotationEffect(.degrees(player.rotation))

            VStack(alignment: .leading, spacing: 2) {
                Text(player.current?.title ?? "Not Playing")
                    .font(.callout).fontWeight(.medium).lineLimit(1)
                Text(player.current?.artistLine ?? "")
                    .font(.caption).foregroundColor(.secondary).lineLimit(1)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.secondary.opacity(0.15)).frame(height: 2)
                        Capsule()
                            .fill(Color.accentColor)
                            .frame(width: geo.size.width * CGFloat(player.progress), height: 2)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { showSeekBarWithAnimation() }
                }
                .frame(height: 2)
                .padding(.vertical, 4)
            }

            Spacer()

            HStack(spacing: 20) {
                Button { player.previous() } label: {
                    Image(systemName: "backward.fill").font(.system(size: 20)).opacity(0.8)
                }
                Button { player.toggle() } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 26))
                }
                Button { player.next() } label: {
                    Image(systemName: "forward.fill").font(.system(size: 20)).opacity(0.8)
                }
            }
            .foregroundColor(.primary)
            .padding(.trailing, 12)
        }
        .padding(.horizontal, 16)
    }

    // MARK: Auto‑hide helpers
    private func scheduleAutoHide() {
        cancelAutoHide()
        let work = DispatchWorkItem { [self] in
            if !isDragging { hideSeekBar() }
        }
        autoHideWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: work)
    }

    private func cancelAutoHide() { autoHideWorkItem?.cancel(); autoHideWorkItem = nil }

    private func hideSeekBar() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { showSeekBar = false }
    }

    private func showSeekBarWithAnimation() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { showSeekBar = true }
        scheduleAutoHide()
    }
}

// MARK: – ElegantSeekBar
struct ElegantSeekBar: View {
    let progress: Double        // 0…1
    @Binding var isDragging: Bool
    @Binding var dragProgress: Double
    let onSeek: (Double) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(formatTime(isDragging ? dragProgress : progress))
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.primary.opacity(0.7))
                .frame(width: 42, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.15)).frame(height: 3)
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: geo.size.width * CGFloat(isDragging ? dragProgress : progress), height: 3)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 14, height: 14)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        .offset(x: geo.size.width * CGFloat(isDragging ? dragProgress : progress) - 7)

                    Rectangle()   // invisible drag layer
                        .fill(Color.clear).contentShape(Rectangle()).frame(height: 30)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    isDragging = true
                                    let x = max(0, min(value.location.x, geo.size.width))
                                    dragProgress = Double(x / geo.size.width)
                                }
                                .onEnded { _ in
                                    onSeek(dragProgress)
                                    isDragging = false
                                }
                        )
                }
            }
            .frame(height: 30)

            Text("-" + formatTime(1 - (isDragging ? dragProgress : progress)))
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.primary.opacity(0.7))
                .frame(width: 42, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .frame(height: 46)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.9))
                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
        )
    }

    // MARK: Time formatting helper
    private func formatTime(_ pct: Double) -> String {
        let duration = 210.0 // TODO: replace with track‑specific duration
        let secs = Int(duration * pct)
        return String(format: "%d:%02d", secs / 60, secs % 60)
    }
}
