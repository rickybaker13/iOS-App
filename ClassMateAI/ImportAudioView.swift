import SwiftUI
import UniformTypeIdentifiers

struct ImportAudioView: View {
    @Binding var isPresented: Bool
    @State private var showingFilePicker = false
    @State private var importedURL: URL?
    @State private var showingSaveDialog = false
    @State private var lectureTitle = ""
    @State private var selectedSubject: Subject?
    @State private var errorMessage: String?
    @State private var showingError = false
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 80))
                    .foregroundColor(.matePrimary)
                    .padding()
                
                Text("Import Audio File")
                    .font(.title2)
                    .foregroundColor(.mateText)
                
                Text("Supported formats: .m4a, .mp3, .wav")
                    .font(.caption)
                    .foregroundColor(.mateText)
                
                Button(action: {
                    showingFilePicker = true
                }) {
                    Text("Choose File")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.matePrimary)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Import Audio")
            .navigationBarItems(leading: Button("Cancel") {
                isPresented = false
            })
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.audio],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        // Create a copy in the app's documents directory
                        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        let fileName = "imported_\(Date().timeIntervalSince1970).m4a"
                        let destinationURL = documentsPath.appendingPathComponent(fileName)
                        
                        do {
                            if FileManager.default.fileExists(atPath: destinationURL.path) {
                                try FileManager.default.removeItem(at: destinationURL)
                            }
                            try FileManager.default.copyItem(at: url, to: destinationURL)
                            importedURL = destinationURL
                            showingSaveDialog = true
                        } catch {
                            errorMessage = "Error copying file: \(error.localizedDescription)"
                            showingError = true
                        }
                    }
                case .failure(let error):
                    errorMessage = "Error selecting file: \(error.localizedDescription)"
                    showingError = true
                }
            }
            .sheet(isPresented: $showingSaveDialog) {
                if let url = importedURL {
                    SaveRecordingView(
                        isPresented: $showingSaveDialog,
                        recordingURL: url,
                        lectureTitle: $lectureTitle,
                        selectedSubject: $selectedSubject,
                        subjects: dataManager.subjects
                    )
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
        }
    }
} 