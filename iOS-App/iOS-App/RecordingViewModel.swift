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
    @Published var recordingTime = "00:00:00"
    @Published var showingNewSubjectSheet = false
    @Published var showingNewSubcategorySheet = false
    
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    
    init() {
        // TODO: Load subjects from storage
    }
    
    func startRecording() {
        // TODO: Implement recording functionality
    }
    
    func stopRecording() {
        // TODO: Implement stop recording
    }
}
