import SwiftUI

struct AudioPlayerBar: View {
    @Bindable var audioService: AudioService

    private let rates: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

    var body: some View {
        HStack(spacing: 16) {
            // Play/Pause
            Button {
                audioService.togglePlayPause()
            } label: {
                Image(systemName: audioService.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title3)
                    .frame(width: 30)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.space, modifiers: [])

            // Rewind 10s
            Button {
                audioService.seekRelative(-10)
            } label: {
                Image(systemName: "gobackward.10")
            }
            .buttonStyle(.plain)

            // Forward 10s
            Button {
                audioService.seekRelative(10)
            } label: {
                Image(systemName: "goforward.10")
            }
            .buttonStyle(.plain)

            // Current time
            Text(TimeFormatting.timestamp(audioService.currentTime))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 60)

            // Scrubber
            Slider(
                value: Binding(
                    get: { audioService.currentTime },
                    set: { audioService.seek(to: $0) }
                ),
                in: 0 ... max(audioService.duration, 0.01)
            )

            // Duration
            Text(TimeFormatting.timestamp(audioService.duration))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 60)

            // Speed
            Menu {
                ForEach(rates, id: \.self) { rate in
                    Button {
                        audioService.setRate(rate)
                    } label: {
                        HStack {
                            Text("\(rate, specifier: rate == floor(rate) ? "%.0f" : "%.2f")x")
                            if rate == audioService.playbackRate {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Text("\(audioService.playbackRate, specifier: audioService.playbackRate == floor(audioService.playbackRate) ? "%.0f" : "%.1f")x")
                    .font(.caption.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(.secondary.opacity(0.2)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.bar)
    }
}
