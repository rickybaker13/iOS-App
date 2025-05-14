//
//  RecordingView.swift
//  iOS-App
//
//  Created by user942277 on 5/3/25.
//

import SwiftUI

struct RecordingView: View {
    @StateObject private var viewModel = RecordingViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Recording Lecture")
                .font(.title)
                .padding()
            
            // Subject Selection
            VStack(alignment: .leading) {
                Text("Subject:")
                HStack {
                    Picker("Select Subject", selection: $viewModel.selectedSubject) {
                        ForEach(viewModel.subjects) { subject in
                            Text(subject.name).tag(subject as Subject?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Button("Add New") {
                        viewModel.showingNewSubjectSheet = true
                    }
                }
            }
            .padding()
            
            // Subcategory Selection
            VStack(alignment: .leading) {
                Text("Subcategory:")
                HStack {
                    Picker("Select Subcategory", selection: $viewModel.selectedSubcategory) {
                        ForEach(viewModel.selectedSubject?.subcategories ?? []) { subcategory in
                            Text(subcategory.name).tag(subcategory as Subcategory?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Button("Add New") {
                        viewModel.showingNewSubcategorySheet = true
                    }
                }
            }
            .padding()
            
            // Recording Controls
            VStack {
                HStack(spacing: 30) {
                    // Record Button
                    Button(action: {
                        if viewModel.isRecording {
                            viewModel.stopRecording()
                        } else {
                            viewModel.startRecording()
                        }
                    }) {
                        Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "record.circle")
                            .font(.system(size: 60))
                            .foregroundColor(viewModel.isRecording ? .red : .blue)
                    }
                    .disabled(viewModel.isPlaying)
                    
                    // Play/Stop Button
                    if viewModel.currentRecordingURL != nil {
                        Button(action: {
                            if viewModel.isPlaying {
                                viewModel.stopPlayback()
                            } else {
                                viewModel.playRecording()
                            }
                        }) {
                            Image(systemName: viewModel.isPlaying ? "stop.circle.fill" : "play.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(viewModel.isPlaying ? .red : .green)
                        }
                        .disabled(viewModel.isRecording)
                    }
                }
                
                Text(viewModel.isRecording ? "Recording..." : 
                     viewModel.isPlaying ? "Playing..." : 
                     viewModel.currentRecordingURL != nil ? "Tap to Record or Play" : "Tap to Record")
                    .font(.headline)
                
                Text(viewModel.recordingTime)
                    .font(.title2)
                    .monospacedDigit()
                
                // Progress Bar and Seeking
                if viewModel.currentRecordingURL != nil {
                    VStack(spacing: 8) {
                        Slider(value: Binding(
                            get: { viewModel.playbackProgress },
                            set: { viewModel.seekTo($0) }
                        ))
                        .disabled(!viewModel.isPlaying)
                        
                        HStack {
                            Text(formatTime(viewModel.playbackProgress * viewModel.duration))
                            Spacer()
                            Text(formatTime(viewModel.duration))
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Playback Speed Control
                    HStack {
                        Text("Speed:")
                            .foregroundColor(.secondary)
                        ForEach(viewModel.availableSpeeds, id: \.self) { speed in
                            Button(action: {
                                viewModel.setPlaybackSpeed(speed)
                            }) {
                                Text("\(speed, specifier: "%.1f")x")
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        viewModel.playbackSpeed == speed ?
                                            Color.blue.opacity(0.2) :
                                            Color.gray.opacity(0.1)
                                    )
                                    .cornerRadius(8)
                            }
                            .disabled(!viewModel.isPlaying)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Volume Control
                    HStack {
                        Image(systemName: "speaker.fill")
                        Slider(value: $viewModel.volume, in: 0...1)
                        Image(systemName: "speaker.wave.3.fill")
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .sheet(isPresented: $viewModel.showingNewSubjectSheet) {
            NewSubjectView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingNewSubcategorySheet) {
            NewSubcategoryView(viewModel: viewModel)
        }
    }
    
    private func formatTime(_ time: Double) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

struct RecordingView_Previews: PreviewProvider {
    static var previews: some View {
        RecordingView()
    }
}
