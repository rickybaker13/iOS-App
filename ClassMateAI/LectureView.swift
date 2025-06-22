import SwiftUI
import AVFoundation
import Combine

struct LectureView: View {
    let lecture: Lecture
    @StateObject private var audioPlayer = AudioPlayer()
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var showingTranscriptionAlert = false
    @State private var transcriptionType: TranscriptionType?
    @State private var isTranscribing = false
    @State private var transcriptionError: String?
    @State private var cancellables = Set<AnyCancellable>()
    @EnvironmentObject var dataManager: DataManager
    @State private var showingCustomTriggers = false
    
    enum TranscriptionType {
        case notes
        case outline
    }
    
    private var subject: Subject? {
        dataManager.subjects.first { $0.id == lecture.subjectId }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Audio Player Section
                VStack(spacing: 15) {
                    HStack {
                        Button(action: {
                            if audioPlayer.isPlaying {
                                audioPlayer.pause()
                            } else if let url = lecture.recordingURL {
                                print("LectureView: Attempting to play audio from URL: \(url)")
                                audioPlayer.play(url: url)
                            }
                        }) {
                            Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.matePrimary)
                        }
                        .disabled(lecture.recordingURL == nil)
                        
                        Text(audioPlayer.formatTime(audioPlayer.currentTime))
                            .font(.title2)
                            .foregroundColor(.mateText)
                    }
                    
                    if let error = audioPlayer.error {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding()
                .background(Color.mateSecondary.opacity(0.1))
                .cornerRadius(10)
                
                // Important Information Button
                NavigationLink(destination: ImportantInfoView(lecture: lecture)) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 24))
                        Text("Important Information")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.matePrimary)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                // Custom Triggers Button
                Button(action: { showingCustomTriggers = true }) {
                    HStack {
                        Image(systemName: "star.fill")
                            .font(.system(size: 24))
                        Text("Custom Triggers")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.mateSecondary)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                // AI Question Button
                NavigationLink(destination: AIQuestionView(lecture: lecture)) {
                    HStack {
                        Image(systemName: "brain")
                            .font(.system(size: 24))
                        Text("Ask AI")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.matePrimary)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(lecture.notes.isEmpty && lecture.outline.isEmpty)
                
                // Transcription Buttons
                HStack(spacing: 20) {
                    Button(action: {
                        transcriptionType = .notes
                        showingTranscriptionAlert = true
                    }) {
                        VStack {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 24))
                            Text("Create Notes")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.matePrimary)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(lecture.recordingURL == nil || isTranscribing)
                    
                    Button(action: {
                        transcriptionType = .outline
                        showingTranscriptionAlert = true
                    }) {
                        VStack {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 24))
                            Text("Create Outline")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.mateSecondary)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(lecture.recordingURL == nil || isTranscribing)
                }
                
                if isTranscribing {
                    VStack(spacing: 10) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Text("Transcribing...")
                            .foregroundColor(.mateText)
                    }
                    .padding()
                }
                
                if let error = transcriptionError {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
                
                // Notes Section
                if !lecture.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Notes")
                            .font(.title2)
                            .foregroundColor(.mateText)
                        
                        Text(lecture.notes)
                            .foregroundColor(.mateText)
                    }
                    .padding()
                    .background(Color.mateSecondary.opacity(0.1))
                    .cornerRadius(10)
                }
                
                // Outline Section
                if !lecture.outline.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Outline")
                            .font(.title2)
                            .foregroundColor(.mateText)
                        
                        Text(lecture.outline)
                            .foregroundColor(.mateText)
                    }
                    .padding()
                    .background(Color.mateSecondary.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            .padding()
        }
        .navigationTitle(lecture.title)
        .background(Color.mateBackground)
        .alert("Start Transcription", isPresented: $showingTranscriptionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Start") {
                startTranscription()
            }
        } message: {
            Text("This will generate \(transcriptionType == .notes ? "notes" : "an outline") from your lecture recording. This may take a few minutes.")
        }
        .onDisappear {
            audioPlayer.stop()
            speechRecognizer.stopTranscription()
        }
        .sheet(isPresented: $showingCustomTriggers) {
            NavigationView {
                CustomTriggersView()
            }
        }
    }
    
    private func startTranscription() {
        guard let type = transcriptionType,
              let recordingURL = lecture.recordingURL else {
            print("LectureView: Cannot start transcription - missing type or recording URL")
            return
        }
        
        print("LectureView: Starting transcription for \(type == .notes ? "notes" : "outline")")
        print("LectureView: Recording URL: \(recordingURL)")
        
        isTranscribing = true
        transcriptionError = nil
        
        speechRecognizer.transcribeAudioFile(url: recordingURL)
        
        // Handle the transcription result
        speechRecognizer.$transcribedText
            .receive(on: DispatchQueue.main)
            .sink { text in
                if !text.isEmpty {
                    print("LectureView: Received transcription text: \(text)")
                    if type == .notes {
                        // Update notes
                        dataManager.updateLecture(lecture, notes: text, outline: lecture.outline)
                        print("LectureView: Updated notes")
                        
                        // Extract important information
                        extractImportantInfo(from: text)
                    } else {
                        // Generate and update outline
                        let outline = OutlineGenerator.generateOutline(from: text)
                        dataManager.updateLecture(lecture, notes: lecture.notes, outline: outline)
                        print("LectureView: Generated and updated outline")
                    }
                }
            }
            .store(in: &cancellables)
        
        // Handle completion
        speechRecognizer.$isTranscribing
            .receive(on: DispatchQueue.main)
            .sink { isTranscribing in
                if !isTranscribing {
                    print("LectureView: Transcription completed")
                    self.isTranscribing = false
                }
            }
            .store(in: &cancellables)
        
        // Handle errors
        speechRecognizer.$error
            .receive(on: DispatchQueue.main)
            .sink { error in
                if let error = error {
                    print("LectureView: Transcription error: \(error)")
                    self.transcriptionError = error
                    self.isTranscribing = false
                }
            }
            .store(in: &cancellables)
    }
    
    private func extractImportantInfo(from text: String) {
        // Check for homework mentions
        if text.lowercased().contains("homework") {
            dataManager.addImportantInfo(
                lectureId: lecture.id,
                text: text,
                type: .homework,
                source: "Automatic Detection"
            )
        }
        
        // Check for test mentions
        if text.lowercased().contains("test") || text.lowercased().contains("exam") {
            dataManager.addImportantInfo(
                lectureId: lecture.id,
                text: text,
                type: .test,
                source: "Automatic Detection"
            )
        }
        
        // Check for quiz mentions
        if text.lowercased().contains("quiz") {
            dataManager.addImportantInfo(
                lectureId: lecture.id,
                text: text,
                type: .quiz,
                source: "Automatic Detection"
            )
        }
        
        // Check custom triggers
        for trigger in dataManager.customTriggers where trigger.isActive {
            if text.lowercased().contains(trigger.phrase.lowercased()) {
                dataManager.addImportantInfo(
                    lectureId: lecture.id,
                    text: text,
                    type: .custom,
                    source: trigger.description
                )
            }
        }
    }
} 