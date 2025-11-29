import SwiftUI

struct SaveRecordingView: View {
    @Binding var isPresented: Bool
    let recordingURL: URL?
    let lectureId: UUID
    @Binding var lectureTitle: String
    @Binding var selectedSubject: Subject?
    @EnvironmentObject var dataManager: DataManager
    let pendingImages: [LectureImage]
    var onSave: ((Lecture) -> Void)?
    var onCancel: (() -> Void)?
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isSaving = false
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Lecture Title", text: $lectureTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.words)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Subject")
                            .font(.headline)
                            .foregroundColor(.mateText)
                        
                        Picker("Select a subject", selection: $selectedSubject) {
                            Text("Choose a subject").tag(nil as Subject?)
                            ForEach(dataManager.subjects) { subject in
                                HStack {
                                    Image(systemName: subject.icon)
                                        .foregroundColor(.matePrimary)
                                    Text(subject.name)
                                }
                                .tag(subject as Subject?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                        .background(Color.mateCardBackground)
                        .cornerRadius(10)
                    }
                } header: {
                    Text("Save Recording")
                } footer: {
                    if dataManager.subjects.isEmpty {
                        Text("No subjects available. Please add a subject first.")
                            .foregroundColor(.orange)
                    }
                }
                
                Section {
                    Button(action: saveRecording) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "square.and.arrow.down")
                            }
                            Text(isSaving ? "Saving..." : "Save Lecture")
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(canSave ? Color.matePrimary : Color.gray)
                        .cornerRadius(10)
                    }
                    .disabled(!canSave || isSaving)
                }
            }
            .navigationTitle("Save Recording")
            .navigationBarItems(
                leading: Button("Cancel") {
                    onCancel?()
                    isPresented = false
                }
                .disabled(isSaving)
            )
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .overlay(
                Group {
                    if showingSuccess {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                            Text("Lecture Saved!")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.mateText)
                            Text("Your recording has been saved successfully.")
                                .font(.subheadline)
                                .foregroundColor(.mateSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(Color.mateCardBackground)
                        .cornerRadius(16)
                        .shadow(radius: 10)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            )
        }
    }
    
    private var canSave: Bool {
        !lectureTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedSubject != nil &&
        recordingURL != nil
    }
    
    private func saveRecording() {
        print("SaveRecordingView: Attempting to save recording")
        print("SaveRecordingView: Available subjects: \(dataManager.subjects.map { $0.name })")
        
        guard let recordingURL = recordingURL else {
            errorMessage = "Missing recording URL"
            showingError = true
            return
        }
        
        guard let selectedSubject = selectedSubject else {
            errorMessage = "Please select a subject"
            showingError = true
            return
        }
        
        let trimmedTitle = lectureTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            errorMessage = "Please enter a lecture title"
            showingError = true
            return
        }
        
        print("SaveRecordingView: Selected subject: \(selectedSubject.name) (ID: \(selectedSubject.id))")
        
        isSaving = true
        
        // Simulate a brief delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            // Create a new lecture
            let newLecture = Lecture(
                id: lectureId,
                title: trimmedTitle,
                date: Date(),
                duration: 0, // TODO: Get actual duration
                recordingURL: recordingURL,
                notes: "",
                outline: "",
                notesTimestamps: nil,
                lectureImages: pendingImages,
                subjectId: selectedSubject.id
            )
            
            print("SaveRecordingView: Created lecture with subject ID: \(newLecture.subjectId)")
            
            // Save the lecture using DataManager
            dataManager.addLecture(newLecture, to: selectedSubject)
            onSave?(newLecture)
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showingSuccess = true
            }
            
            // Dismiss after showing success
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isPresented = false
            }
        }
    }
} 