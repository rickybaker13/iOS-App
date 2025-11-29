import Foundation
import AVFoundation

class AudioPlayer: NSObject, ObservableObject {
    private var player: AVAudioPlayer?
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var error: String?
    @Published var isSeeking = false
    
    private var timer: Timer?
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
            self.error = "Failed to set up audio playback"
        }
    }
    
    func play(url: URL) {
        do {
            // Stop any existing playback
            stop()
            
            // Create a new player
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.prepareToPlay()
            
            // Set duration
            duration = player?.duration ?? 0
            
            // Start playback
            if player?.play() == true {
                isPlaying = true
                startTimer()
                error = nil
            } else {
                error = "Failed to start playback"
            }
        } catch {
            print("Failed to play audio: \(error)")
            self.error = "Failed to play audio: \(error.localizedDescription)"
        }
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
        stopTimer()
    }
    
    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        stopTimer()
    }
    
    func seek(to time: TimeInterval) {
        guard let player = player else { return }
        player.currentTime = min(max(0, time), duration)
        currentTime = player.currentTime
    }
    
    func seekToProgress(_ progress: Double) {
        let newTime = duration * progress
        seek(to: newTime)
    }
    
    func fastForward() {
        guard let player = player else { return }
        let newTime = min(currentTime + 30, duration)
        seek(to: newTime)
    }
    
    func rewind() {
        guard let player = player else { return }
        let newTime = max(currentTime - 15, 0)
        seek(to: newTime)
    }
    
    func skipForward() {
        guard let player = player else { return }
        let newTime = min(currentTime + 10, duration)
        seek(to: newTime)
    }
    
    func skipBackward() {
        guard let player = player else { return }
        let newTime = max(currentTime - 10, 0)
        seek(to: newTime)
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.player else { return }
            if !self.isSeeking {
                self.currentTime = player.currentTime
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func formatDuration() -> String {
        return formatTime(duration)
    }
    
    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }
}

extension AudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.isPlaying = false
            self?.currentTime = 0
            self?.stopTimer()
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.error = "Playback error: \(error?.localizedDescription ?? "Unknown error")"
            self?.isPlaying = false
            self?.stopTimer()
        }
    }
} 
} 