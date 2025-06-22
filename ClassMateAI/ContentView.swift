import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddSubject = false
    
    var body: some View {
        TabView {
            NavigationView {
                List {
                    Section(header: Text("My Subjects")) {
                        ForEach(dataManager.subjects) { subject in
                            NavigationLink(destination: SubjectView(subject: subject)) {
                                SubjectRow(subject: subject)
                            }
                        }
                        
                        Button(action: {
                            showingAddSubject = true
                        }) {
                            Label("Add Subject", systemImage: "plus.circle.fill")
                                .foregroundColor(.matePrimary)
                        }
                    }
                    
                    Section(header: Text("Recent Lectures")) {
                        ForEach(dataManager.subjects.flatMap { $0.lectures }.prefix(3)) { lecture in
                            NavigationLink(destination: LectureView(lecture: lecture)) {
                                LectureRow(lecture: lecture)
                            }
                        }
                    }
                }
                .navigationTitle("ClassMate.ai")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            // Settings action
                        }) {
                            Image(systemName: "gear")
                                .foregroundColor(.matePrimary)
                        }
                    }
                }
                .sheet(isPresented: $showingAddSubject) {
                    AddSubjectView(subjects: $dataManager.subjects)
                }
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            
            RecordingView()
                .tabItem {
                    Label("Record", systemImage: "mic.fill")
                }
        }
        .accentColor(.matePrimary)
    }
}

struct SubjectRow: View {
    let subject: Subject
    
    var body: some View {
        HStack {
            Image(systemName: subject.icon)
                .font(.system(size: 24))
                .foregroundColor(.matePrimary)
                .frame(width: 40, height: 40)
                .background(Color.mateBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading) {
                Text(subject.name)
                    .font(.headline)
                    .foregroundColor(.mateText)
                Text("\(subject.lectures.count) Lectures")
                    .font(.subheadline)
                    .foregroundColor(.mateSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.mateSecondary)
        }
        .padding(.vertical, 4)
    }
}

struct LectureRow: View {
    let lecture: Lecture
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(lecture.title)
                    .font(.headline)
                    .foregroundColor(.mateText)
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.mateSecondary)
                    Text(lecture.date, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.mateSecondary)
                    
                    Image(systemName: "clock")
                        .foregroundColor(.mateSecondary)
                    Text(formatDuration(lecture.duration))
                        .font(.subheadline)
                        .foregroundColor(.mateSecondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.mateSecondary)
        }
        .padding(.vertical, 4)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        return "\(minutes) min"
    }
}

struct RecordingView: View {
    @State private var isRecording = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Recording Status
                VStack {
                    Image(systemName: isRecording ? "waveform.circle.fill" : "waveform.circle")
                        .font(.system(size: 80))
                        .foregroundColor(isRecording ? .red : .matePrimary)
                        .padding()
                    
                    Text(isRecording ? "Recording..." : "Ready to Record")
                        .font(.title2)
                        .foregroundColor(.mateText)
                }
                
                // Recording Controls
                HStack(spacing: 40) {
                    Button(action: {
                        // Stop recording
                        isRecording = false
                    }) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.mateSecondary)
                    }
                    .disabled(!isRecording)
                    
                    Button(action: {
                        // Start/Stop recording
                        isRecording.toggle()
                    }) {
                        Image(systemName: isRecording ? "pause.circle.fill" : "record.circle")
                            .font(.system(size: 64))
                            .foregroundColor(isRecording ? .red : .matePrimary)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Record Lecture")
            .background(Color.mateBackground)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DataManager())
} 