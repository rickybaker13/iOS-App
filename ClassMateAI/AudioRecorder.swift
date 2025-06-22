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
    
    override init() {
        super.init()
        checkPermissions()
    }
    
    private func checkPermissions() {
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted:
                setupAudioSession()
            case .denied:
                error = "Microphone access denied. Please enable it in Settings."
            case .undetermined:
                AVAudioApplication.shared.requestRecordPermission { [weak self] granted in
                    DispatchQueue.main.async {
                        if granted {
                            self?.setupAudioSession()
                        } else {
                            self?.error = "Microphone access denied"
                        }
                    }
                }
            @unknown default:
                error = "Unknown permission status"
            }
        } else {
            // Fallback for iOS 16 and earlier
            switch AVAudioSession.sharedInstance().recordPermission {
            case .granted:
                setupAudioSession()
            case .denied:
                error = "Microphone access denied. Please enable it in Settings."
            case .undetermined:
                AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                    DispatchQueue.main.async {
                        if granted {
                            self?.setupAudioSession()
                        } else {
                            self?.error = "Microphone access denied"
                        }
                    }
                }
            @unknown default:
                error = "Unknown permission status"
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
        if #available(iOS 17.0, *) {
            guard AVAudioApplication.shared.recordPermission == .granted else {
                error = "Microphone access required"
                return
            }
        } else {
            guard AVAudioSession.sharedInstance().recordPermission == .granted else {
                error = "Microphone access required"
                return
            }
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
                AVNumberOfChannelsKey: 2,
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
                startTime = Date()
                recordingURL = fileURL
                startTimer()
                error = nil
            } else {
                error = "Failed to start recording"
            }
        } catch {
            self.error = "Failed to start recording: \(error.localizedDescription)"
        }
    }
    
    func pauseRecording() {
        audioRecorder?.pause()
        isPaused = true
        stopTimer()
    }
    
    func resumeRecording() {
        if audioRecorder?.record() == true {
            isPaused = false
            startTime = Date().addingTimeInterval(-recordingTime)
            startTimer()
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        isPaused = false
        stopTimer()
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.startTime else { return }
            self.recordingTime = Date().timeIntervalSince(startTime)
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
        }
    }
} 