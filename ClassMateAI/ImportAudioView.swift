import SwiftUI
import UniformTypeIdentifiers

struct ImportAudioView: View {
    @Binding var isPresented: Bool
    @State private var showingFilePicker = false
    @State private var importedURL: URL?
    @State private var showingSaveDialog = false
    @State private var lectureTitle = ""
    @State private var selectedSubject: Subject?
    @State private var lectureId = UUID()
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var isImporting = false
    @State private var showingSuccess = false
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if showingSuccess {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                        
                        Text("File Imported!")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.mateText)
                        
                        Text("Your audio file has been successfully imported.")
                            .font(.subheadline)
                            .foregroundColor(.mateSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.mateCardBackground)
                    .cornerRadius(16)
                    .shadow(radius: 10)
                    .transition(.scale.combined(with: .opacity))
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 80))
                            .foregroundColor(.matePrimary)
                            .padding()
                        
                        VStack(spacing: 8) {
                            Text("Import Audio File")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.mateText)
                            
                            Text("Supported formats: .m4a, .mp3, .wav")
                                .font(.subheadline)
                                .foregroundColor(.mateSecondary)
                        }
                        
                        if isImporting {
                            VStack(spacing: 12) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Text("Importing file...")
                                    .font(.subheadline)
                                    .foregroundColor(.mateSecondary)
                            }
                            .padding()
                        } else {
                            Button(action: {
                                showingFilePicker = true
                            }) {
                                HStack {
                                    Image(systemName: "doc.badge.plus")
                                    Text("Choose Audio File")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.matePrimary)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
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
                handleFileImport(result)
            }
            .sheet(isPresented: $showingSaveDialog) {
                if let url = importedURL {
                    SaveRecordingView(
                        isPresented: $showingSaveDialog,
                        recordingURL: url,
                        lectureId: lectureId,
                        lectureTitle: $lectureTitle,
                        selectedSubject: $selectedSubject,
                        pendingImages: [],
                        onSave: { _ in
                            resetStateForNextImport()
                        },
                        onCancel: {
                            resetStateForNextImport()
                        }
                    )
                    .environmentObject(dataManager)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                isImporting = true
                
                // Create a copy in the app's documents directory
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let fileName = "imported_\(Date().timeIntervalSince1970).m4a"
                let destinationURL = documentsPath.appendingPathComponent(fileName)
                
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        if FileManager.default.fileExists(atPath: destinationURL.path) {
                            try FileManager.default.removeItem(at: destinationURL)
                        }
                        try FileManager.default.copyItem(at: url, to: destinationURL)
                        
                        DispatchQueue.main.async {
                            lectureId = UUID()
                            importedURL = destinationURL
                            isImporting = false
                            
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                showingSuccess = true
                            }
                            
                            // Show save dialog after success animation
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                showingSaveDialog = true
                            }
                        }
                    } catch {
                        DispatchQueue.main.async {
                            isImporting = false
                            errorMessage = "Error copying file: \(error.localizedDescription)"
                            showingError = true
                        }
                    }
                }
            }
        case .failure(let error):
            errorMessage = "Error selecting file: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func resetStateForNextImport() {
        lectureId = UUID()
        lectureTitle = ""
        selectedSubject = nil
        importedURL = nil
        showingSuccess = false
    }
} 