import AVFoundation
import Foundation

@Observable
final class AudioService {
    private var player: AVAudioPlayer?
    private var timer: Timer?

    var isPlaying = false
    var currentTime: Double = 0
    var duration: Double = 0
    var playbackRate: Float = 1.0
    var isLoaded = false

    func load(url: URL) throws {
        stop()
        player = try AVAudioPlayer(contentsOf: url)
        player?.prepareToPlay()
        player?.enableRate = true
        duration = player?.duration ?? 0
        currentTime = 0
        isLoaded = true
    }

    func play() {
        guard let player else { return }
        player.rate = playbackRate
        player.play()
        isPlaying = true
        startTimer()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        stopTimer()
    }

    func togglePlayPause() {
        if isPlaying { pause() } else { play() }
    }

    func seek(to time: Double) {
        let clamped = max(0, min(time, duration))
        player?.currentTime = clamped
        currentTime = clamped
    }

    func seekRelative(_ delta: Double) {
        seek(to: currentTime + delta)
    }

    func setRate(_ rate: Float) {
        playbackRate = rate
        if isPlaying {
            player?.rate = rate
        }
    }

    func stop() {
        player?.stop()
        stopTimer()
        isPlaying = false
        currentTime = 0
        isLoaded = false
        player = nil
    }

    /// Retourne l'index du segment en cours de lecture
    func currentSegmentIndex(in segments: [Segment]) -> Int? {
        segments.firstIndex { seg in
            currentTime >= seg.startTime && currentTime < seg.endTime
        }
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self, let player = self.player else { return }
            self.currentTime = player.currentTime
            if !player.isPlaying {
                self.isPlaying = false
                self.stopTimer()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
