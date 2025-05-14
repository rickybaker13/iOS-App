//
//  RecordingViewModel.swift
//  iOS-App
//
//  Created by user942277 on 5/3/25.
//

import Foundation
import AVFoundation

class RecordingViewModel: ObservableObject {
    @Published var subjects: [Subject] = []
    @Published var selectedSubject: Subject?
    @Published var selectedSubcategory: Subcategory?
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var recordingTime = "00:00:00"
    @Published var showingNewSubjectSheet = false
    @Published var showingNewSubcategorySheet = false
    @Published var errorMessage: String?
    @Published var currentRecordingURL: URL?
    @Published var playbackProgress: Double = 0
    @Published var duration: Double = 0
    @Published var volume: Float = 1.0 {
        didSet {
            audioPlayer?.volume = volume
        }
    }
    @Published var playbackSpeed: Double = 1.0 {
        didSet {
            audioPlayer?.rate = Float(playbackSpeed)
        }
    }
    
    let availableSpeeds: [Double] = [0.5, 1.0, 1.5, 2.0]
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var recordingStartTime: Date?
    private var audioSession: AVAudioSession?
    
    init() {
        setupAudioSession()
        // TODO: Load subjects from storage
    }
    
    private func setupAudioSession() {
        audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession?.setCategory(.playAndRecord, mode: .default)
            try audioSession?.setActive(true)
        } catch {
            errorMessage = "Failed to setup audio session: \(error.localizedDescription)"
        }
    }
    
    func startRecording() {
        guard let subject = selectedSubject, let subcategory = selectedSubcategory else {
            errorMessage = "Please select a subject and subcategory"
            return
        }
        
        let audioFilename = getDocumentsDirectory().appendingPathComponent("\(subject.name)_\(subcategory.name)_\(Date().timeIntervalSince1970).m4a")
        currentRecordingURL = audioFilename
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            isRecording = true
            recordingStartTime = Date()
            startTimer()
        } catch {
            errorMessage = "Could not start recording: \(error.localizedDescription)"
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        stopTimer()
        recordingStartTime = nil
        recordingTime = "00:00:00"
    }
    
    func playRecording() {
        guard let url = currentRecordingURL else {
            errorMessage = "No recording available to play"
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.volume = volume
            audioPlayer?.enableRate = true
            audioPlayer?.rate = Float(playbackSpeed)
            audioPlayer?.play()
            isPlaying = true
            duration = audioPlayer?.duration ?? 0
            startTimer()
            recordingStartTime = Date().addingTimeInterval(-audioPlayer!.currentTime)
        } catch {
            errorMessage = "Could not play recording: \(error.localizedDescription)"
        }
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
        isPlaying = false
        stopTimer()
        recordingStartTime = nil
        recordingTime = "00:00:00"
        playbackProgress = 0
    }
    
    func seekTo(_ progress: Double) {
        guard let player = audioPlayer else { return }
        let time = progress * player.duration
        player.currentTime = time
        updatePlaybackProgress()
    }
    
    func setPlaybackSpeed(_ speed: Double) {
        playbackSpeed = speed
        if isPlaying {
            audioPlayer?.rate = Float(speed)
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateRecordingTime()
            self?.updatePlaybackProgress()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateRecordingTime() {
        if isPlaying {
            guard let player = audioPlayer else { return }
            let duration = player.currentTime
            let hours = Int(duration) / 3600
            let minutes = Int(duration) / 60 % 60
            let seconds = Int(duration) % 60
            recordingTime = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else if let startTime = recordingStartTime {
            let duration = Date().timeIntervalSince(startTime)
            let hours = Int(duration) / 3600
            let minutes = Int(duration) / 60 % 60
            let seconds = Int(duration) % 60
            recordingTime = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
    }
    
    private func updatePlaybackProgress() {
        guard let player = audioPlayer else { return }
        playbackProgress = player.currentTime / player.duration
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

extension RecordingViewModel: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        stopTimer()
        recordingTime = "00:00:00"
        playbackProgress = 0
    }
}
