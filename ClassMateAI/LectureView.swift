import SwiftUI
import AVFoundation
import Combine
import UniformTypeIdentifiers
    
    enum TranscriptionType {
        case notes
        case outline
    }
    
struct ActionButton: View {
    let icon: String
    let title: String
    let backgroundColor: Color
    
    var body: some View {
                    HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
            Text(title)
                            .font(.headline)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
        .background(backgroundColor)
                    .foregroundColor(.white)
        .cornerRadius(12)
    }
}

struct TranscriptionButton: View {
    let icon: String
    let title: String
    let backgroundColor: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                            .font(.system(size: 24))
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(backgroundColor)
                    .foregroundColor(.white)
        .cornerRadius(12)
                }
}

struct LectureContentView: View {
    let lecture: Lecture
    let audioPlayer: AudioPlayer
    let openAITranscriptionService: OpenAITranscriptionService
    let dataManager: DataManager
    let visualAssistant: VisualLectureAssistant

    // All the @Binding properties
    @Binding var showingTranscriptionAlert: Bool
    @Binding var showingDeleteAlert: Bool
    @Binding var showingMoveAlert: Bool
    @Binding var showingNotesView: Bool
    @Binding var showingOutlineView: Bool
    @Binding var showingCustomTriggers: Bool
    @Binding var showingVisualCapture: Bool
    @Binding var showingVisualGallery: Bool
    @Binding var showingDocumentPicker: Bool
    @Binding var showingDocumentScanner: Bool
    @Binding var showingAIQuestion: Bool
    @Binding var showingDeleteNotesAlert: Bool
    @Binding var showingDeleteOutlineAlert: Bool
    @Binding var lectureResourcePreview: ResourcePreviewItem?
    @Binding var showingLectureFilesList: Bool

    let startTranscription: () -> Void
    let deleteLecture: () -> Void
    let deleteNotes: () -> Void
    let deleteOutline: () -> Void
    
    let lectureMenuButton: () -> AnyView

    var body: some View {
        ZStack {
            Color.mateBackground.edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text(lecture.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.mateText)
                        .multilineTextAlignment(.center)

                    Text(dataManager.subjects.first(where: { $0.id == lecture.subjectId })?.name ?? "Unknown Subject")
                        .font(.subheadline)
                        .foregroundColor(.mateSecondary)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 16)

                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        LectureAudioSectionView(lecture: lecture, audioPlayer: audioPlayer)
                            .padding(.horizontal)

                        LectureActionsSectionView(
                            lecture: lecture,
                            showingTranscriptionAlert: $showingTranscriptionAlert,
                            showingDeleteAlert: $showingDeleteAlert,
                            showingMoveAlert: $showingMoveAlert,
                            showingCustomTriggers: $showingCustomTriggers,
                            showingVisualCapture: $showingVisualCapture,
                            showingVisualGallery: $showingVisualGallery,
                            showingDocumentPicker: $showingDocumentPicker,
                            showingDocumentScanner: $showingDocumentScanner,
                            showingAIQuestion: $showingAIQuestion,
                            startTranscription: startTranscription,
                            deleteLecture: deleteLecture
                        )
                        .padding(.horizontal)

                        LectureMaterialsSectionView(
                            lecture: lecture,
                            dataManager: dataManager,
                            showingVisualGallery: $showingVisualGallery,
                            showingLectureFilesList: $showingLectureFilesList,
                            showingNotesView: $showingNotesView,
                            showingOutlineView: $showingOutlineView
                        )
                        .padding(.horizontal)

                        LectureTranscriptionSectionView(
                            lecture: lecture,
                            transcriptionService: openAITranscriptionService,
                            startTranscription: startTranscription
                        )
                        .padding(.horizontal)

                        Spacer(minLength: 0)
                            .frame(height: 1)
                            .padding(.bottom, 20)
                    }
                    .padding(.vertical, 20)
                }
            }
        }
        .navigationTitle(lecture.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                lectureMenuButton()
            }
        }
    }
}

struct LectureView: View {
    let lectureId: UUID
    @EnvironmentObject var dataManager: DataManager
    
    init(lecture: Lecture) {
        self.lectureId = lecture.id
    }
    
    init(lectureId: UUID) {
        self.lectureId = lectureId
    }
    
    private var lecture: Lecture {
        dataManager.subjects.flatMap { $0.lectures }.first { $0.id == lectureId }
            ?? Lecture(id: lectureId, title: "Loading...", subjectId: UUID())
    }
    @StateObject private var audioPlayer = AudioPlayer()
    @StateObject private var openAITranscriptionService = OpenAITranscriptionService()
    @StateObject private var timestampedTranscriptionService = TimestampedTranscriptionService()
    @StateObject private var visualAssistant = VisualLectureAssistant()

    @State private var isTranscribing = false
    @State private var transcriptionType: TranscriptionType = .notes
    @State private var transcriptionError: String?
    @State private var showingTranscriptionAlert = false
    @State private var showingDeleteAlert = false
    @State private var showingMoveAlert = false
    @State private var showingCustomTriggers = false
    @State private var showingSuccessMessage = false
    @State private var successMessage = ""
    @State private var showingDeleteNotesAlert = false
    @State private var showingDeleteOutlineAlert = false
    @State private var showingSaveSuccessMessage = false
    @State private var saveSuccessMessage = ""
    @State private var showingNotesView = false
    @State private var showingOutlineView = false
    @State private var showingVisualCapture = false
    @State private var showingVisualGallery = false
    @State private var showingLectureFilesList = false
    @State private var didSyncInitialVisuals = false
    @StateObject private var lectureResourceImporter = LectureResourceImportService()
    @State private var showingDocumentPicker = false
    @State private var showingDocumentScanner = false
    @State private var showingAIQuestion = false
    @State private var lectureResourcePreview: ResourcePreviewItem?

    @State private var cancellables = Set<AnyCancellable>()
    
    // Get the current lecture data from DataManager
    // private var currentLecture: Lecture? { ... } - Removed as lecture is now computed
    
    var body: some View {
        LectureContentView(
            lecture: lecture,
            audioPlayer: audioPlayer,
            openAITranscriptionService: openAITranscriptionService,
            dataManager: dataManager,
            visualAssistant: visualAssistant,
            showingTranscriptionAlert: $showingTranscriptionAlert,
            showingDeleteAlert: $showingDeleteAlert,
            showingMoveAlert: $showingMoveAlert,
            showingNotesView: $showingNotesView,
            showingOutlineView: $showingOutlineView,
            showingCustomTriggers: $showingCustomTriggers,
            showingVisualCapture: $showingVisualCapture,
            showingVisualGallery: $showingVisualGallery,
            showingDocumentPicker: $showingDocumentPicker,
            showingDocumentScanner: $showingDocumentScanner,
            showingAIQuestion: $showingAIQuestion,
            showingDeleteNotesAlert: $showingDeleteNotesAlert,
            showingDeleteOutlineAlert: $showingDeleteOutlineAlert,
            lectureResourcePreview: $lectureResourcePreview,
            showingLectureFilesList: $showingLectureFilesList,
            startTranscription: startTranscription,
            deleteLecture: deleteLecture,
            deleteNotes: deleteNotes,
            deleteOutline: deleteOutline,
            lectureMenuButton: { AnyView(self.LectureMenuButton()) }
        )
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPickerView(
                supportedTypes: [
                    UTType.pdf,
                    UTType.plainText,
                    UTType.rtf,
                    UTType.text,
                    UTType.png,
                    UTType.jpeg,
                    UTType.heic
                ]
            ) { url in
                lectureResourceImporter.importDocument(from: url, lecture: lecture, dataManager: dataManager)
            }
            .onAppear {
                print("=== DOCUMENT PICKER SHEET PRESENTED ===")
            }
        }
        .sheet(isPresented: $showingDocumentScanner) {
            DocumentScannerView { result in
                switch result {
                case .success(let data):
                    lectureResourceImporter.importScannedDocument(
                        data: data,
                        lecture: lecture,
                        dataManager: dataManager,
                        suggestedTitle: "Scanned Notes"
                    )
                case .failure(let error):
                    lectureResourceImporter.lastError = error.localizedDescription
                }
                showingDocumentScanner = false
            }
            .onAppear {
                print("=== DOCUMENT SCANNER SHEET PRESENTED ===")
            }
        }
        .sheet(isPresented: $showingAIQuestion) {
            AIQuestionView(lecture: lecture)
        }
        .sheet(item: $lectureResourcePreview) { item in
            ResourcePreviewController(item: item)
        }
        .alert("Start Transcription", isPresented: $showingTranscriptionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Start") {
                startTranscription()
            }
        } message: {
            Text("This will generate detailed notes from your lecture recording. This may take a few minutes.")
        }
        .alert("Delete Lecture", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteLecture()
            }
        } message: {
            Text("Are you sure you want to delete this lecture? This action cannot be undone.")
        }
        .alert("Delete Notes", isPresented: $showingDeleteNotesAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteNotes()
            }
        } message: {
            Text("Are you sure you want to delete these notes? This action cannot be undone.")
        }
        .alert("Delete Outline", isPresented: $showingDeleteOutlineAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteOutline()
            }
        } message: {
            Text("Are you sure you want to delete this outline? This action cannot be undone.")
        }
        .onDisappear {
            audioPlayer.stop()
            openAITranscriptionService.stopTranscription()
        }
        .sheet(isPresented: $showingCustomTriggers) {
            NavigationView {
                CustomTriggersView()
            }
        }
        .sheet(isPresented: $showingMoveAlert) {
            MoveLectureView(lecture: lecture)
                .environmentObject(dataManager)
        }
        .sheet(isPresented: $showingNotesView) {
            NotesView(lecture: lecture)
                .environmentObject(dataManager)
        }
        .sheet(isPresented: $showingOutlineView) {
            OutlineView(lecture: lecture)
                .environmentObject(dataManager)
        }
        .sheet(isPresented: $showingVisualCapture) {
            VisualCaptureView(lectureId: lecture.id, visualAssistant: visualAssistant)
                .environmentObject(dataManager)
        }
        .sheet(isPresented: $showingVisualGallery) {
            LectureVisualsGalleryView(
                lectureId: lecture.id,
                visualAssistant: visualAssistant
            )
            .environmentObject(dataManager)
        }
        .sheet(isPresented: $showingLectureFilesList) {
            LectureFilesListView(
                lecture: lecture,
                dataManager: dataManager,
                lectureResourcePreview: $lectureResourcePreview
            )
        }
        .overlay(
            SuccessMessageOverlay()
        )
        .background(Color.mateCardBackground)
        .onReceive(dataManager.objectWillChange) { _ in
            let storedImages = dataManager.getLectureImages(for: lecture.id)
            if !storedImages.isEmpty {
                visualAssistant.replaceImages(storedImages, for: lecture.id)
            }
        }
        .onAppear {
            if !didSyncInitialVisuals {
                let storedImages = dataManager.getLectureImages(for: lecture.id)
                if !storedImages.isEmpty {
                    visualAssistant.replaceImages(storedImages, for: lecture.id)
                }
                didSyncInitialVisuals = true
            }
        }
        .alert(
            "Upload Failed",
            isPresented: Binding(
                get: { lectureResourceImporter.lastError != nil },
                set: { if !$0 { lectureResourceImporter.lastError = nil } }
            )
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(lectureResourceImporter.lastError ?? "")
        }
    }


    @ViewBuilder
    private func LectureMenuButton() -> some View {
        Menu {
            Button(action: { showingMoveAlert = true }) {
                Label("Move Lecture", systemImage: "folder")
            }

            Button(action: { showingDeleteAlert = true }) {
                Label("Delete Lecture", systemImage: "trash")
            }
            .foregroundColor(.red)
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundColor(.matePrimary)
        }
    }

    @ViewBuilder
    private func SuccessMessageOverlay() -> some View {
        Group {
            if showingSuccessMessage {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                    Text(successMessage)
                        .font(.headline)
                        .foregroundColor(.mateText)
                }
                .padding()
                .background(Color.mateCardBackground)
                .cornerRadius(12)
                .shadow(radius: 5)
                .transition(.scale.combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingSuccessMessage = false
                        }
                    }
                }
            }
        }
    }
    
    private func startTranscription() {
        let type = transcriptionType
        
        guard let recordingURL = lecture.recordingURL else {
            print("LectureView: Cannot start transcription - missing recording URL")
            transcriptionError = "Cannot start transcription: missing recording file"
            return
        }
        
        print("LectureView: Starting transcription for \(type == .notes ? "notes" : "outline")")
        print("LectureView: Recording URL: \(recordingURL)")
        print("LectureView: File exists: \(FileManager.default.fileExists(atPath: recordingURL.path))")
        
        // Check file size
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: recordingURL.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            print("LectureView: File size: \(fileSize) bytes")
            
            if fileSize < 1000 {
                transcriptionError = "Audio file is too small. Please ensure you have a valid recording."
                return
            }
        } catch {
            print("LectureView: Error checking file attributes: \(error)")
        }
        
        isTranscribing = true
        transcriptionError = nil
        
        // Reset transcription service
        openAITranscriptionService.reset()
        
        // Start transcription using async/await
        Task {
            do {
            if type == .notes {
                    print("LectureView: Starting regular transcription for notes (will add timestamps later)")
                    let transcription = try await openAITranscriptionService.transcribeAudioFile(url: recordingURL)
                    
                    await MainActor.run {
                        print("LectureView: Transcription completed successfully")
                        self.isTranscribing = false
                        
                        if transcription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            self.transcriptionError = "Transcription completed but no text was generated. This might be due to:\n\n• Audio quality issues\n• Background noise\n• Speech not clearly spoken\n• File format problems\n\nPlease try recording again with clearer speech."
                        } else {
                            print("LectureView: Processing transcription result with generated timestamps")
                            // Create simple timestamps based on the transcription
                            let timestamps = self.createSimpleTimestamps(from: transcription)
                            self.processTimestampedTranscriptionResult(text: transcription, timestamps: timestamps, type: type)
                        }
                    }
                } else {
                    print("LectureView: Starting regular transcription for outline")
                    let transcription = try await openAITranscriptionService.transcribeAudioFile(url: recordingURL)
                    
                    await MainActor.run {
                        print("LectureView: Transcription completed successfully")
                        self.isTranscribing = false
                        
                        if transcription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            self.transcriptionError = "Transcription completed but no text was generated. This might be due to:\n\n• Audio quality issues\n• Background noise\n• Speech not clearly spoken\n• File format problems\n\nPlease try recording again with clearer speech."
            } else {
                            print("LectureView: Processing transcription result")
                            self.processTranscriptionResult(text: transcription, type: type)
                    }
                }
            }
            } catch {
                await MainActor.run {
                    print("LectureView: Transcription error: \(error)")
                    self.transcriptionError = error.localizedDescription
                    self.isTranscribing = false
                }
            }
        }
        
        // Monitor progress updates
        openAITranscriptionService.$transcriptionProgress
            .receive(on: DispatchQueue.main)
            .sink { progress in
                print("LectureView: Transcription progress: \(progress * 100)%")
            }
            .store(in: &cancellables)
        
        // Monitor error updates
        openAITranscriptionService.$error
            .receive(on: DispatchQueue.main)
            .sink { error in
                if let error = error {
                    print("LectureView: Transcription service error: \(error)")
                    self.transcriptionError = error
                    self.isTranscribing = false
                }
            }
            .store(in: &cancellables)
    }
    
    private func processTranscriptionResult(text: String, type: TranscriptionType) {
        print("LectureView: Processing transcription result for \(type == .notes ? "notes" : "outline")")
        print("LectureView: Text length: \(text.count)")
        print("LectureView: Text preview: \(String(text.prefix(300)))...")
        
        if type == .notes {
            // Generate AI-powered notes
            Task {
                do {
                    print("LectureView: About to generate AI notes from \(text.count) characters")
                    let notes = try await NotesGenerator.generateNotes(from: text)
                    print("LectureView: AI notes generated successfully: \(notes.count) characters")
                    print("LectureView: Notes preview: '\(String(notes.prefix(200)))'")
                    
                    await MainActor.run {
                        // Update the lecture with new notes
                        self.dataManager.updateLecture(self.lecture, notes: notes, outline: self.lecture.outline)
                        print("LectureView: Called dataManager.updateLecture")
                        
                        // Force UI refresh
                        self.dataManager.objectWillChange.send()
                        print("LectureView: Forced UI refresh")
                        
                        // Extract important information
                        self.extractImportantInfo(from: text)
                        
                        // Show success message
                        self.showingSuccessMessage = true
                        self.successMessage = "Notes generated successfully!"
                        
                        // Automatically navigate to notes view after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            self.showingNotesView = true
                        }
                    }
                } catch {
                    await MainActor.run {
                        print("LectureView: AI notes generation failed: \(error)")
                        self.transcriptionError = "Failed to generate notes: \(error.localizedDescription)"
                        self.isTranscribing = false
                    }
                }
            }
        } else {
            // Generate and update outline
            Task {
                do {
                    print("LectureView: About to generate AI outline from \(text.count) characters")
                    let outline = try await OutlineGenerator.generateOutline(from: text)
                    print("LectureView: AI outline generated successfully: \(outline.count) characters")
                    
                    await MainActor.run {
                        self.dataManager.updateLecture(self.lecture, notes: self.lecture.notes, outline: outline)
                        print("LectureView: Called dataManager.updateLecture for outline")
                        
                        // Force UI refresh
                        self.dataManager.objectWillChange.send()
                        print("LectureView: Forced UI refresh for outline")
                        
                        // Show success message
                        self.showingSuccessMessage = true
                        self.successMessage = "Outline generated successfully!"
                        
                        // Automatically navigate to outline view after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            self.showingOutlineView = true
                        }
                    }
                } catch {
                    await MainActor.run {
                        print("LectureView: AI outline generation failed: \(error)")
                        self.transcriptionError = "Failed to generate outline: \(error.localizedDescription)"
                        self.isTranscribing = false
                    }
                }
            }
        }
    }
    
    private func processTimestampedTranscriptionResult(text: String, timestamps: [NotesTimestamp], type: TranscriptionType) {
        print("LectureView: Processing timestamped transcription result for \(type == .notes ? "notes" : "outline")")
        print("LectureView: Text length: \(text.count)")
        print("LectureView: Timestamps count: \(timestamps.count)")
        print("LectureView: Text preview: \(String(text.prefix(300)))...")
        
        if type == .notes {
            // Generate AI-powered notes with timestamps
            Task {
                do {
                    print("LectureView: About to generate AI notes with timestamps from \(text.count) characters")
                    print("LectureView: Input timestamps count: \(timestamps.count)")
                    for (index, ts) in timestamps.enumerated() {
                        print("LectureView: Input timestamp \(index): \(ts.sectionTitle) at \(ts.timestamp)s")
                    }
                    
                    let (notes, sectionTimestamps) = try await TimestampedNotesGenerator.generateNotesWithTimestamps(from: text, timestamps: timestamps)
                    print("LectureView: AI notes with timestamps generated successfully: \(notes.count) characters, \(sectionTimestamps.count) sections")
                    print("LectureView: Notes preview: '\(String(notes.prefix(200)))'")
                    
                    for (index, ts) in sectionTimestamps.enumerated() {
                        print("LectureView: Output timestamp \(index): \(ts.sectionTitle) at \(ts.timestamp)s")
                    }
                    
                    await MainActor.run {
                        // Update the lecture with new notes and timestamps
                        self.dataManager.updateNotesWithTimestamps(for: self.lecture, notes: notes, timestamps: sectionTimestamps)
                        print("LectureView: Called dataManager.updateNotesWithTimestamps")
                        
                        // Force UI refresh
                        self.dataManager.objectWillChange.send()
                        print("LectureView: Forced UI refresh")
                        
                        // Extract important information
                        self.extractImportantInfo(from: text)
                        
                        // Show success message
                        self.showingSuccessMessage = true
                        self.successMessage = "Notes with timestamps generated successfully!"
                        
                        // Automatically navigate to notes view after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            self.showingNotesView = true
                        }
                    }
                } catch {
                    await MainActor.run {
                        print("LectureView: AI notes with timestamps generation failed: \(error)")
                        self.transcriptionError = "Failed to generate notes: \(error.localizedDescription)"
                        self.isTranscribing = false
                    }
                }
            }
        } else {
            // For outlines, use the regular process
            processTranscriptionResult(text: text, type: type)
        }
    }
    
    private func deleteLecture() {
        dataManager.deleteLecture(lecture)
        // Force UI refresh and navigate back
        DispatchQueue.main.async {
            dataManager.objectWillChange.send()
        }
    }
    
    private func deleteNotes() {
        dataManager.deleteNotes(for: lecture)
    }
    
    private func deleteOutline() {
        dataManager.deleteOutline(for: lecture)
    }
    
    private func createSimpleTimestamps(from transcription: String) -> [NotesTimestamp] {
        print("LectureView: Creating simple timestamps from transcription of \(transcription.count) characters")
        
        // Split transcription into sentences to create sections
        let sentences = transcription.components(separatedBy: [".", "!", "?"])
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        let maxSections = min(5, sentences.count)
        var timestamps: [NotesTimestamp] = []
        
        // Estimate time per section based on average speaking rate (150 words per minute)
        let wordsPerMinute: Double = 150
        let words = transcription.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let totalDuration = Double(words.count) / wordsPerMinute * 60 // Convert to seconds
        let timePerSection = totalDuration / Double(maxSections)
        
        print("LectureView: Estimated total duration: \(totalDuration)s, time per section: \(timePerSection)s")
        
        for i in 0..<maxSections {
            let startTime = Double(i) * timePerSection
            let sectionTitle = "Section \(i + 1)"
            
            let timestamp = NotesTimestamp(
                sectionTitle: sectionTitle,
                timestamp: startTime,
                startIndex: i * (transcription.count / maxSections),
                endIndex: (i + 1) * (transcription.count / maxSections)
            )
            timestamps.append(timestamp)
            
            print("LectureView: Created timestamp \(i + 1): \(sectionTitle) at \(startTime)s")
        }
        
        return timestamps
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
    
    // MARK: - File Saving Functions
    
    private func saveNotesToFile(notes: String, lectureTitle: String) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "\(lectureTitle)_Notes.txt"
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "\\", with: "_")
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try notes.write(to: fileURL, atomically: true, encoding: .utf8)
            print("LectureView: Notes saved to \(fileURL)")
            
            // Show success message
            showingSuccessMessage = true
            successMessage = "Notes saved to Documents folder"
        } catch {
            print("LectureView: Error saving notes: \(error)")
            transcriptionError = "Failed to save notes: \(error.localizedDescription)"
        }
    }
    
    private func saveOutlineToFile(outline: String, lectureTitle: String) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "\(lectureTitle)_Outline.txt"
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "\\", with: "_")
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try outline.write(to: fileURL, atomically: true, encoding: .utf8)
            print("LectureView: Outline saved to \(fileURL)")
            
            // Show success message
            showingSuccessMessage = true
            successMessage = "Outline saved to Documents folder"
        } catch {
            print("LectureView: Error saving outline: \(error)")
            transcriptionError = "Failed to save outline: \(error.localizedDescription)"
        }
    }
    
    private func handleLectureResourceTap(_ resource: LectureResource) {
        if let url = ResourceStorageService.shared.localFileURL(for: resource) {
            lectureResourcePreview = ResourcePreviewItem(url: url, title: resource.title)
        } else if let remoteURL = resource.remoteURL {
            UIApplication.shared.open(remoteURL)
        }
    }
}

private struct LectureResourceRow: View {
    let resource: LectureResource
    
    var body: some View {
        HStack {
            Image(systemName: iconName(for: resource.type))
                .foregroundColor(.matePrimary)
            VStack(alignment: .leading, spacing: 4) {
                Text(resource.title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.mateSecondary)
            }
            Spacer()
            if resource.hasLocalFile {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color.mateCardBackground)
        .cornerRadius(10)
    }
    
    private var subtitle: String {
        var parts = [resource.type.displayName]
        parts.append(relativeDate(from: resource.importedAt))
        if let size = resource.sizeInBytes {
            parts.append(CourseResource.displayFormatter(for: size))
        }
        return parts.joined(separator: " • ")
    }
    
    private func iconName(for type: LectureResource.ResourceType) -> String {
        switch type {
        case .pdf: return "doc.richtext"
        case .document: return "doc.text"
        case .image: return "photo"
        case .audio: return "waveform"
        case .link: return "link"
        case .other: return "doc"
        }
    }
    
    private func relativeDate(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct MoveLectureView: View {
    let lecture: Lecture
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedSubject: Subject?
    @State private var showingSuccess = false
    @State private var isMoving = false
    
    private var availableSubjects: [Subject] {
        dataManager.subjects.filter { $0.id != lecture.subjectId }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Move Lecture")) {
                    Text("'\(lecture.title)'")
                        .font(.headline)
                        .foregroundColor(.mateText)
                    
                    Text("Select a new subject to move this lecture to:")
                        .font(.subheadline)
                        .foregroundColor(.mateSecondary)
                }
                
                Section(header: Text("Available Subjects")) {
                    if availableSubjects.isEmpty {
                        Text("No other subjects available")
                            .foregroundColor(.mateSecondary)
                            .italic()
                    } else {
                        ForEach(availableSubjects) { subject in
                            Button(action: {
                                selectedSubject = subject
                            }) {
                                HStack {
                                    Image(systemName: subject.icon)
                                        .foregroundColor(.matePrimary)
                                        .frame(width: 30, height: 30)
                                    
                                    Text(subject.name)
                                        .foregroundColor(.mateText)
                                    
                                    Spacer()
                                    
                                    if selectedSubject?.id == subject.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.matePrimary)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(isMoving)
                        }
                    }
                }
            }
            .navigationTitle("Move Lecture")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
                .disabled(isMoving),
                trailing: Button("Move") {
                    if let targetSubject = selectedSubject {
                        moveLecture(to: targetSubject)
                    }
                }
                .disabled(selectedSubject == nil || isMoving)
            )
            .overlay(
                Group {
                    if showingSuccess {
                        VStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.green)
                            Text("Lecture Moved!")
                                .font(.headline)
                                .foregroundColor(.mateText)
                        }
                        .padding()
                        .background(Color.mateCardBackground)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            )
        }
    }
    
    private func moveLecture(to targetSubject: Subject) {
        isMoving = true
        print("MoveLectureView: Moving lecture '\(lecture.title)' to subject '\(targetSubject.name)'")
        
        // Perform the move
        dataManager.moveLecture(lecture, to: targetSubject)
        
        // Show success message
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showingSuccess = true
        }
        
        // Dismiss after a short delay and navigate back
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            dismiss()
            // Force refresh of the data
            dataManager.objectWillChange.send()
        }
    }
} 