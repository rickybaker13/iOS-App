import SwiftUI

struct RecordingView: View {
    @StateObject private var audioRecorder = AudioRecorder()
    @EnvironmentObject var dataManager: DataManager
    @State private var showingSaveDialog = false
    @State private var showingImportSheet = false
    @State private var lectureTitle = ""
    @State private var selectedSubject: Subject?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Recording Status
                VStack {
                    Image(systemName: audioRecorder.isRecording ? (audioRecorder.isPaused ? "pause.circle.fill" : "waveform.circle.fill") : "waveform.circle")
                        .font(.system(size: 80))
                        .foregroundColor(audioRecorder.isRecording ? (audioRecorder.isPaused ? .orange : .red) : .matePrimary)
                        .padding()
                    
                    Text(audioRecorder.isRecording ? (audioRecorder.isPaused ? "Paused" : "Recording...") : "Ready to Record")
                        .font(.title2)
                        .foregroundColor(.mateText)
                }
                
                // Recording Controls
                HStack(spacing: 40) {
                    Button(action: {
                        audioRecorder.stopRecording()
                        showingSaveDialog = true
                    }) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.mateSecondary)
                    }
                    .disabled(!audioRecorder.isRecording)
                    
                    Button(action: {
                        if audioRecorder.isRecording {
                            if audioRecorder.isPaused {
                                audioRecorder.resumeRecording()
                            } else {
                                audioRecorder.pauseRecording()
                            }
                        } else {
                            audioRecorder.startRecording()
                        }
                    }) {
                        Image(systemName: audioRecorder.isRecording ? (audioRecorder.isPaused ? "play.circle.fill" : "pause.circle.fill") : "record.circle")
                            .font(.system(size: 64))
                            .foregroundColor(audioRecorder.isRecording ? (audioRecorder.isPaused ? .green : .red) : .matePrimary)
                    }
                }
                
                if audioRecorder.isRecording {
                    // Recording Timer
                    Text(audioRecorder.formatTime(audioRecorder.recordingTime))
                        .font(.title)
                        .foregroundColor(.mateText)
                        .padding()
                }
                
                if let error = audioRecorder.error {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
                
                // Import Button
                Button(action: {
                    showingImportSheet = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Import Audio File")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.mateSecondary)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(audioRecorder.isRecording)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Record Lecture")
            .background(Color.mateBackground)
            .sheet(isPresented: $showingSaveDialog) {
                SaveRecordingView(
                    isPresented: $showingSaveDialog,
                    recordingURL: audioRecorder.recordingURL,
                    lectureTitle: $lectureTitle,
                    selectedSubject: $selectedSubject,
                    subjects: dataManager.subjects
                )
            }
            .sheet(isPresented: $showingImportSheet) {
                ImportAudioView(isPresented: $showingImportSheet)
            }
        }
    }
} 