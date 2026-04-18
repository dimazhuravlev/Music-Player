import SwiftUI

/// Horizontal mini player matching Figma «Tabbar • New Navigation» — visual only; taps are no-ops until wired.
struct MiniPlayerV2: View {
    let track: Track
    @ObservedObject private var audioPlayer = AudioPlayerManager.shared

    @State private var coverRotation: Double = 0
    @State private var lastTimelineDate: Date = Date()

    private let coverDegreesPerSecond: Double = 18

    private let barHeight: CGFloat = 56
    /// Figma `bottom stack` / mini-player: pill height 56 → полный капсулярный радиус 28 (`rounded-[52px]` в макете — по высоте ограничивается половиной).
    private let cornerRadius: CGFloat = 100
    private let coverSize: CGFloat = 48

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(red: 20 / 255, green: 20 / 255, blue: 20 / 255).opacity(0.72))

                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)

                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .frame(width: max(0, w * CGFloat(audioPlayer.progress)))
                    .animation(.easeOut(duration: 0.12), value: audioPlayer.progress)

                HStack(spacing: 12) {
                    TimelineView(.animation) { timeline in
                        CachedAsyncImage(url: track.albumCoverURL, assetName: track.albumCover)
                            .frame(width: coverSize, height: coverSize)
                            .clipShape(Circle())
                            .rotationEffect(.degrees(coverRotation))
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.08), lineWidth: 0.66)
                            )
                            .onChange(of: timeline.date) { _, newTime in
                                let delta = newTime.timeIntervalSince(lastTimelineDate)
                                coverRotation += coverDegreesPerSecond * delta
                                coverRotation = coverRotation.truncatingRemainder(dividingBy: 360)
                                lastTimelineDate = newTime
                            }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title)
                            .font(.Text2)
                            .foregroundColor(.fill1)
                            .lineLimit(1)
                        Text(track.artist)
                            .font(.Text2)
                            .foregroundColor(.subtitle)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Figma: actions 24×24, gap 18; fill/one on icons (template tint).
                    HStack(spacing: 18) {
                        Image("like-default")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.fill1)
                            .frame(width: 24, height: 24)

                        Image("pause")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.fill1)
                            .frame(width: 24, height: 24)
                    }
                }
                .padding(.leading, 6)
                .padding(.trailing, 18)
                .padding(.vertical, 6)
            }
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.66)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        .frame(height: barHeight)
        .contentShape(Rectangle())
        // Visual-only for now: absorb taps so the bar does not navigate or control playback.
        .onTapGesture { }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(track.title), \(track.artist)")
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        MiniPlayerV2(
            track: TrackDataManager.shared.getSampleTracks().first
                ?? Track(id: 0, title: "Strawberry Line", artist: "Cocteau Twins", albumCover: "album", releaseYear: 1984)
        )
        .padding(.horizontal, 24)
    }
}
