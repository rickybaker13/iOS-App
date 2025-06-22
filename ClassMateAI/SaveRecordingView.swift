import SwiftUI

struct SaveRecordingView: View {
    @Binding var isPresented: Bool
    let recordingURL: URL?
    @Binding var lectureTitle: String
    @Binding var selectedSubject: Subject?
    let subjects: [Subject]
    @EnvironmentObject var dataManager: DataManager
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Lecture Title", text: $lectureTitle)
                    
                    Picker("Subject", selection: $selectedSubject) {
                        Text("Select a subject").tag(nil as Subject?)
                        ForEach(subjects) { subject in
                            Text(subject.name).tag(subject as Subject?)
                        }
                    }
                } header: {
                    Text("Save Recording")
                }
            }
            .navigationTitle("Save Recording")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                },
                trailing: Button("Save") {
                    saveRecording()
                }
                .disabled(lectureTitle.isEmpty || selectedSubject == nil)
            )
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveRecording() {
        print("SaveRecordingView: Attempting to save recording")
        guard let recordingURL = recordingURL,
              let selectedSubject = selectedSubject else {
            errorMessage = "Missing recording or subject"
            showingError = true
            return
        }
        
        // Create a new lecture
        let newLecture = Lecture(
            id: UUID(),
            title: lectureTitle,
            date: Date(),
            duration: 0, // TODO: Get actual duration
            recordingURL: recordingURL,
            notes: "",
            outline: "",
            subjectId: selectedSubject.id
        )
        
        // Save the lecture using DataManager
        dataManager.addLecture(newLecture, to: selectedSubject)
        
        isPresented = false
    }
} 