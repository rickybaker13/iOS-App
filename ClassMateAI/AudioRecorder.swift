import Foundation
import AVFoundation

class AudioRecorder: NSObject, ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    @Published var isRecording = false
    @Published var isPaused = false
    @Published var recordingTime: TimeInterval = 0
    @Published var error: String?
    @Published var recordingURL: URL?
    
    private var timer: Timer?
    private var startTime: Date?
    private var totalPausedTime: TimeInterval = 0
    
    override init() {
        super.init()
        checkPermissions()
    }
    
    private func checkPermissions() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.setupAudioSession()
                } else {
                    self?.error = "Microphone access denied. Please enable it in Settings."
                }
            }
        }
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up audio session: \(error)")
            self.error = "Failed to set up audio recording"
        }
    }
    
    func startRecording() {
        // Check if we have permission
        guard AVAudioSession.sharedInstance().recordPermission == .granted else {
            error = "Microphone access required. Please grant permission in Settings."
            return
        }
        
        do {
            // Create a unique file URL
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = "recording_\(Date().timeIntervalSince1970).m4a"
            let fileURL = documentsPath.appendingPathComponent(fileName)
            
            // Configure recording settings
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
                AVEncoderBitRateKey: 128000
            ]
            
            // Create and configure recorder
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.prepareToRecord()
            
            // Start recording
            if audioRecorder?.record() == true {
                isRecording = true
                isPaused = false
                recordingTime = 0
                totalPausedTime = 0
                startTime = Date()
                recordingURL = fileURL
                startTimer()
                error = nil
                print("AudioRecorder: Started recording successfully")
            } else {
                error = "Failed to start recording"
                print("AudioRecorder: Failed to start recording")
            }
        } catch {
            self.error = "Failed to start recording: \(error.localizedDescription)"
            print("AudioRecorder: Recording error: \(error)")
        }
    }
    
    func pauseRecording() {
        audioRecorder?.pause()
        isPaused = true
        stopTimer()
        print("AudioRecorder: Recording paused")
    }
    
    func resumeRecording() {
        if audioRecorder?.record() == true {
            isPaused = false
            startTimer()
            print("AudioRecorder: Recording resumed")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        isPaused = false
        stopTimer()
        print("AudioRecorder: Recording stopped")
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.startTime else { return }
            self.recordingTime = Date().timeIntervalSince(startTime) - self.totalPausedTime
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
}

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            if !flag {
                self?.error = "Recording failed"
                print("AudioRecorder: Recording failed")
            } else {
                print("AudioRecorder: Recording finished successfully")
            }
            self?.isRecording = false
            self?.stopTimer()
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.error = "Recording error: \(error?.localizedDescription ?? "Unknown error")"
            self?.isRecording = false
            self?.stopTimer()
            print("AudioRecorder: Recording error occurred: \(error?.localizedDescription ?? "Unknown error")")
        }
    }
} 