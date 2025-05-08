import SwiftUI
import AVFoundation

/// Two-tier now-playing bar.
/// • Collapsed → controls card only.
/// • Playing   → metadata card slides up, disc protrudes & spins.
struct NowPlayingBar: View {

    @EnvironmentObject private var player: AudioPlayer
    @Namespace private var ns

    private let disc: CGFloat = 90
    private let controlsH: CGFloat = 96
    private let metaH: CGFloat = 110

    var body: some View {
        let expanded = player.isPlaying

        ZStack(alignment: .bottomLeading) {

            // controls card – always visible
            Card(height: controlsH) {
                HStack {
                    Spacer(minLength: disc + 12)    // leave room for disc
                    Controls()
                    Spacer()
                }
                .padding(.horizontal, 32)
            }

            // metadata card – only while playing
            if expanded {
                Card(height: metaH) {
                    TrackInfo(disc: disc)
                        .padding(.horizontal, 32)
                }
                .offset(y: -controlsH + 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // protruding artwork
            Artwork(diameter: disc)
                .matchedGeometryEffect(id: "disc", in: ns)
                .offset(x: 0, y: -disc / 2)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .animation(.easeInOut(duration: 0.25), value: player.isPlaying)
    }
}

// MARK: – Sub-views
// -----------------------------------------------------------

private struct Card<Content: View>: View {
    let height: CGFloat; let content: Content
    init(height: CGFloat, @ViewBuilder _ c: ()->Content) { self.height = height; content = c() }
    var body: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(content)
            .frame(height: height)
            .shadow(radius: 6)
    }
}

private struct Controls: View {
    @EnvironmentObject private var player: AudioPlayer
    var body: some View {
        HStack(spacing: 48) {
            Button(action: { player.previous() }) {
                Image(systemName: "backward.fill")
            }
            Button(action: { player.toggle() }) {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
            }
            Button(action: { player.next() }) {
                Image(systemName: "forward.fill")
            }
        }
        .font(.system(size: 28, weight: .medium))
        .foregroundColor(.secondary)
    }
}

private struct TrackInfo: View {
    @EnvironmentObject private var player: AudioPlayer
    let disc: CGFloat                       // for leading inset

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(player.current?.title ?? "—")
                .font(.headline).lineLimit(1)
            Text(player.current?.artistLine ?? "")
                .font(.footnote)
                .foregroundColor(.secondary)
                .lineLimit(1)
            ProgressView(value: player.progress)
                .tint(.accentColor)
        }
        .padding(.leading, disc + 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct Artwork: View {
    @EnvironmentObject private var player: AudioPlayer
    let diameter: CGFloat
    var body: some View {
        Group {
            if let d = player.current?.artworkData,
               let img = UIImage(data: d) {
                Image(uiImage: img).resizable().scaledToFill()
            } else {
                Image(systemName: "opticaldisc")
                    .resizable().scaledToFit()
                    .padding(14).foregroundColor(.secondary)
            }
        }
        .frame(width: diameter, height: diameter)
        .clipShape(Circle())
        .shadow(radius: 3)
        .rotationEffect(.degrees(player.rotation))
        .animation(player.isPlaying
                   ? .linear(duration: 20).repeatForever(autoreverses: false)
                   : .default, value: player.rotation)
        .onAppear { player.startRotation() }
    }
}
