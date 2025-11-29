import SwiftUI

struct LectureVisualsGalleryView: View {
    let lectureId: UUID
    @ObservedObject var visualAssistant: VisualLectureAssistant
    @EnvironmentObject private var dataManager: DataManager
    @State private var didSyncInitialImages = false
    
    @State private var selectedImage: LectureImage?
    @State private var isSavingToPhotos = false
    @State private var saveConfirmationMessage: String?
    
    private var lectureImages: [LectureImage] {
        dataManager.getLectureImages(for: lectureId)
    }
    
    var body: some View {
        NavigationView {
            Group {
                if lectureImages.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundColor(.mateSecondary)
                        
                        Text("No visuals captured yet")
                            .font(.title3)
                            .foregroundColor(.mateText)
                        
                        Text("Use the Capture Visual button to snap important images during the lecture.")
                            .font(.subheadline)
                            .foregroundColor(.mateSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.mateBackground)
                } else {
                    List {
                        ForEach(lectureImages) { image in
                            Button {
                                selectedImage = image
                            } label: {
                                LectureImageRow(lectureImage: image, visualAssistant: visualAssistant)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete(perform: deleteImages)
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Lecture Visuals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !lectureImages.isEmpty {
                        EditButton()
                    }
                }
            }
            .onAppear {
                if !didSyncInitialImages {
                    let stored = dataManager.getLectureImages(for: lectureId)
                    if !stored.isEmpty {
                        visualAssistant.replaceImages(stored, for: lectureId)
                    }
                    didSyncInitialImages = true
                }
            }
            .onReceive(dataManager.objectWillChange) { _ in
                let stored = dataManager.getLectureImages(for: lectureId)
                visualAssistant.replaceImages(stored, for: lectureId)
            }
            .sheet(item: $selectedImage) { image in
                LectureImageDetailView(
                    lectureImage: image,
                    visualAssistant: visualAssistant,
                    onDelete: {
                        deleteImages(offsets: IndexSet(integer: lectureImages.firstIndex(where: { $0.id == image.id }) ?? 0))
                    },
                    onSaveToPhotos: {
                        Task {
                            await saveImageToPhotos(image)
                        }
                    }
                )
                .environmentObject(dataManager)
            }
            .alert("Saved", isPresented: .constant(saveConfirmationMessage != nil)) {
                Button("OK") {
                    saveConfirmationMessage = nil
                }
            } message: {
                Text(saveConfirmationMessage ?? "")
            }
        }
        .accentColor(.matePrimary)
    }
    
    private func deleteImages(offsets: IndexSet) {
        let indices = offsets.sorted(by: >)
        for index in indices {
            let currentImages = lectureImages
            guard currentImages.indices.contains(index) else { continue }
            let image = currentImages[index]
            visualAssistant.deleteImage(image)
            dataManager.removeLectureImage(image)
        }
    }
    
    @MainActor
    private func saveImageToPhotos(_ image: LectureImage) async {
        guard !isSavingToPhotos else { return }
        
        isSavingToPhotos = true
        await visualAssistant.exportImageToPhotoLibrary(image)
        if visualAssistant.error == nil {
            saveConfirmationMessage = "Saved to Photos"
        }
        isSavingToPhotos = false
    }
}

private struct LectureImageRow: View {
    let lectureImage: LectureImage
    @ObservedObject var visualAssistant: VisualLectureAssistant
    
    private var subtitle: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: lectureImage.timestamp)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            if let uiImage = visualAssistant.loadImage(named: lectureImage.imageFileName, lectureId: lectureImage.lectureId) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.mateSecondary.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay {
                        Image(systemName: "photo.fill")
                            .foregroundColor(.mateSecondary)
                    }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(lectureImage.description?.isEmpty == false ? lectureImage.description! : "Lecture Visual")
                    .font(.headline)
                    .foregroundColor(.mateText)
                    .lineLimit(2)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.mateSecondary)
                
                if let aiAnalysis = lectureImage.aiAnalysis, !aiAnalysis.isEmpty {
                    Text(aiAnalysis)
                        .font(.caption)
                        .foregroundColor(.mateSecondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.mateSecondary)
        }
        .padding(.vertical, 8)
    }
}

private struct LectureImageDetailView: View {
    let lectureImage: LectureImage
    @ObservedObject var visualAssistant: VisualLectureAssistant
    let onDelete: () -> Void
    let onSaveToPhotos: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if let uiImage = visualAssistant.loadImage(named: lectureImage.imageFileName, lectureId: lectureImage.lectureId) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding()
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.mateSecondary.opacity(0.2))
                            .frame(height: 280)
                            .overlay {
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.mateSecondary)
                            }
                            .padding()
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        if let description = lectureImage.description, !description.isEmpty {
                            Text(description)
                                .font(.headline)
                                .foregroundColor(.mateText)
                        }
                        
                        Text("Captured on \(lectureImage.timestamp.formatted(date: .abbreviated, time: .shortened))")
                            .font(.subheadline)
                            .foregroundColor(.mateSecondary)
                        
                        if let analysis = lectureImage.aiAnalysis, !analysis.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("AI Analysis")
                                    .font(.headline)
                                    .foregroundColor(.mateText)
                                
                                Text(analysis)
                                    .font(.body)
                                    .foregroundColor(.mateText)
                            }
                        }
                        
                        if !lectureImage.questions.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Questions")
                                    .font(.headline)
                                    .foregroundColor(.mateText)
                                
                                ForEach(lectureImage.questions) { question in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(question.question)
                                            .font(.subheadline)
                                            .foregroundColor(.mateText)
                                        
                                        Text(question.answer)
                                            .font(.caption)
                                            .foregroundColor(.mateSecondary)
                                    }
                                    .padding(8)
                                    .background(Color.mateSecondary.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        Button {
                            onSaveToPhotos()
                        } label: {
                            Label("Save to Photos", systemImage: "square.and.arrow.down")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete Image", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 24)
            }
            .background(Color.mateBackground.ignoresSafeArea())
            .navigationTitle("Visual Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "Delete this image?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    onDelete()
                    dismiss()
                }
            } message: {
                Text("This will permanently remove the image from the app and delete the file from storage.")
            }
        }
    }
}

