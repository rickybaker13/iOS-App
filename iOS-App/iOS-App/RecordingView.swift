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
                Button(action: {
                    viewModel.isRecording.toggle()
                }) {
                    Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "record.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                }
                
                Text(viewModel.isRecording ? "Recording..." : "Tap to Record")
                    .font(.headline)
                
                Text(viewModel.recordingTime)
                    .font(.title2)
                    .monospacedDigit()
            }
            .padding()
        }
        .sheet(isPresented: $viewModel.showingNewSubjectSheet) {
            NewSubjectView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingNewSubcategorySheet) {
            NewSubcategoryView(viewModel: viewModel)
        }
    }
}

struct RecordingView_Previews: PreviewProvider {
    static var previews: some View {
        RecordingView()
    }
}
