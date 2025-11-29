import SwiftUI
import UIKit
import Foundation
import Photos

class VisualLectureAssistant: ObservableObject {
    @Published var isCapturing = false
    @Published var capturedImages: [LectureImage] = []
    @Published var currentAnalysis: String = ""
    @Published var isAnalyzing = false
    @Published var error: String?
    @Published var storagePreference: StoragePreference = .device
    
    let cameraManager = CameraManager()
    private let aiService = AIService()
    private let fileManager = FileManager.default
    
    init() {
        loadStoragePreference()
    }
    
    // MARK: - Camera Management
    
    func startCamera() {
        cameraManager.startSession()
    }
    
    func stopCamera() {
        cameraManager.stopSession()
    }
    
    @discardableResult
    func captureImage(for lectureId: UUID, description: String? = nil) async -> LectureImage? {
        guard cameraManager.isSessionRunning else {
            cameraManager.recordLog("VisualLectureAssistant: captureImage aborted, session not running")
            await MainActor.run {
                self.error = "Camera is not ready"
            }
            return nil
        }
        
        cameraManager.recordLog("VisualLectureAssistant: captureImage starting for lecture \(lectureId)")
        
        await MainActor.run {
            self.isCapturing = true
        }
        
        do {
            let image = try await cameraManager.capturePhoto()
            let imageFileName = "\(UUID().uuidString).jpg"
            cameraManager.recordLog("VisualLectureAssistant: capture complete, saving as \(imageFileName)")
            
            // Save image based on storage preference
            try await saveImage(image, withName: imageFileName, lectureId: lectureId)
            
            // Create lecture image record
            let lectureImage = LectureImage(
                lectureId: lectureId,
                imageFileName: imageFileName,
                description: description
            )
            
            await MainActor.run {
                self.capturedImages.append(lectureImage)
                self.isCapturing = false
            }
            
            cameraManager.recordLog("VisualLectureAssistant: Captured image \(imageFileName) for lecture \(lectureId)")
            return lectureImage
            
        } catch {
            cameraManager.recordLog("VisualLectureAssistant: capture failed with error \(error.localizedDescription)")
            await MainActor.run {
                self.error = "Failed to capture image: \(error.localizedDescription)"
                self.isCapturing = false
            }
            return nil
        }
    }
    
    // MARK: - Image Storage
    
    private func saveImage(_ image: UIImage, withName fileName: String, lectureId: UUID) async throws {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            cameraManager.recordLog("VisualLectureAssistant: saveImage failed, unable to create JPEG data")
            throw VisualLectureError.imageProcessingFailed
        }
        
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imagesPath = documentsPath.appendingPathComponent("LectureImages")
        let lecturePath = imagesPath.appendingPathComponent(lectureId.uuidString)
        cameraManager.recordLog("VisualLectureAssistant: Saving image to \(lecturePath.appendingPathComponent(fileName).path)")
        
        // Create images directory if it doesn't exist
        if !fileManager.fileExists(atPath: imagesPath.path) {
            try fileManager.createDirectory(at: imagesPath, withIntermediateDirectories: true)
        }
        
        if !fileManager.fileExists(atPath: lecturePath.path) {
            try fileManager.createDirectory(at: lecturePath, withIntermediateDirectories: true)
        }
        
        let imageURL = lecturePath.appendingPathComponent(fileName)
        try imageData.write(to: imageURL)
        
        cameraManager.recordLog("VisualLectureAssistant: Image saved to \(imageURL.lastPathComponent)")
    }
    
    func loadImage(named fileName: String, lectureId: UUID) -> UIImage? {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imagesPath = documentsPath.appendingPathComponent("LectureImages")
        let lecturePath = imagesPath.appendingPathComponent(lectureId.uuidString)
        let imageURL = lecturePath.appendingPathComponent(fileName)
        cameraManager.recordLog("VisualLectureAssistant: Loading image from \(imageURL.path)")
        
        return UIImage(contentsOfFile: imageURL.path)
    }
    
    // MARK: - AI Analysis
    
    func analyzeImage(
        _ lectureImage: LectureImage,
        question: String,
        lectureContext: String? = nil,
        dataManager: DataManager? = nil
    ) async {
        guard let image = loadImage(named: lectureImage.imageFileName, lectureId: lectureImage.lectureId) else {
            await MainActor.run {
                self.error = "Could not load image for analysis"
            }
            return
        }
        
        await MainActor.run {
            self.isAnalyzing = true
            self.currentAnalysis = ""
        }
        
        do {
            let analysis = try await aiService.analyzeImageWithVision(
                image: image,
                question: question,
                lectureContext: lectureContext
            )
            
            await MainActor.run {
                self.currentAnalysis = analysis
                self.isAnalyzing = false
            }
            
            // Save the analysis to the lecture image
            await saveAnalysisToImage(lectureImage, analysis: analysis, question: question)

            if let dataManager = dataManager {
                let imageQuestion = ImageQuestion(question: question, answer: analysis)
                await MainActor.run {
                    dataManager.appendQuestion(imageQuestion, to: lectureImage.id, lectureId: lectureImage.lectureId)
                }
            }
            
        } catch {
            await MainActor.run {
                self.error = "Analysis failed: \(error.localizedDescription)"
                self.isAnalyzing = false
            }
        }
    }
    
    private func saveAnalysisToImage(_ lectureImage: LectureImage, analysis: String, question: String) async {
        // Create a new question record
        let imageQuestion = ImageQuestion(question: question, answer: analysis)
        
        // Update the lecture image with the new question
        if let index = capturedImages.firstIndex(where: { $0.id == lectureImage.id }) {
            await MainActor.run {
                var updatedImage = capturedImages[index]
                var questions = updatedImage.questions
                questions.append(imageQuestion)
                updatedImage = updatedImage.updating(aiAnalysis: analysis, questions: questions)
                capturedImages[index] = updatedImage
                print("VisualLectureAssistant: Saved analysis for image \(lectureImage.imageFileName)")
            }
        }
    }
    
    // MARK: - Storage Preferences
    
    private func loadStoragePreference() {
        if let savedPreference = UserDefaults.standard.string(forKey: "StoragePreference"),
           let preference = StoragePreference(rawValue: savedPreference) {
            storagePreference = preference
        }
    }
    
    func updateStoragePreference(_ preference: StoragePreference) {
        storagePreference = preference
        UserDefaults.standard.set(preference.rawValue, forKey: "StoragePreference")
    }
    
    // MARK: - Image Management
    
    func deleteImage(_ lectureImage: LectureImage) {
        // Remove from array
        capturedImages.removeAll { $0.id == lectureImage.id }
        
        // Delete file
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imagesPath = documentsPath.appendingPathComponent("LectureImages")
        let lecturePath = imagesPath.appendingPathComponent(lectureImage.lectureId.uuidString)
        let imageURL = lecturePath.appendingPathComponent(lectureImage.imageFileName)
        
        do {
            try fileManager.removeItem(at: imageURL)
            print("VisualLectureAssistant: Deleted image \(lectureImage.imageFileName)")
        } catch {
            print("VisualLectureAssistant: Failed to delete image: \(error)")
        }
    }
    
    func exportImageToPhotoLibrary(_ lectureImage: LectureImage) async {
        guard let image = loadImage(named: lectureImage.imageFileName, lectureId: lectureImage.lectureId) else {
            await MainActor.run {
                self.error = "Unable to load image for export"
            }
            return
        }
        
        let authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch authorizationStatus {
        case .authorized, .limited:
            await saveImageToPhotoLibrary(image)
        case .notDetermined:
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            if status == .authorized || status == .limited {
                await saveImageToPhotoLibrary(image)
            } else {
                await MainActor.run {
                    self.error = "Photo Library access denied. Enable it in Settings to save images."
                }
            }
        default:
            await MainActor.run {
                self.error = "Photo Library access denied. Enable it in Settings to save images."
            }
        }
    }
    
    private func saveImageToPhotoLibrary(_ image: UIImage) async {
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
            await MainActor.run {
                self.error = nil
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to save image to Photos: \(error.localizedDescription)"
            }
        }
    }
    
    func deleteImages(for lectureId: UUID) {
        let imagesToDelete = capturedImages.filter { $0.lectureId == lectureId }
        for image in imagesToDelete {
            deleteImage(image)
        }
        
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imagesPath = documentsPath.appendingPathComponent("LectureImages")
        let lecturePath = imagesPath.appendingPathComponent(lectureId.uuidString)
        
        if fileManager.fileExists(atPath: lecturePath.path) {
            do {
                try fileManager.removeItem(at: lecturePath)
                print("VisualLectureAssistant: Deleted directory for lecture \(lectureId)")
            } catch {
                print("VisualLectureAssistant: Failed to delete lecture directory: \(error)")
            }
        }
    }
    
    func getImagesForLecture(_ lectureId: UUID) -> [LectureImage] {
        return capturedImages.filter { $0.lectureId == lectureId }
            .sorted { $0.timestamp > $1.timestamp }
    }
    
    func seedImages(_ images: [LectureImage]) {
        let existingIds = Set(capturedImages.map { $0.id })
        let newImages = images.filter { !existingIds.contains($0.id) }
        if !newImages.isEmpty {
            capturedImages.append(contentsOf: newImages)
        }
        capturedImages = capturedImages.sorted { $0.timestamp > $1.timestamp }
    }
    
    func replaceImages(_ images: [LectureImage], for lectureId: UUID) {
        let remaining = capturedImages.filter { $0.lectureId != lectureId }
        capturedImages = (remaining + images).sorted { $0.timestamp > $1.timestamp }
    }
}

// MARK: - Visual Lecture Error
enum VisualLectureError: Error, LocalizedError {
    case imageProcessingFailed
    case storageError
    case analysisFailed
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "Failed to process image"
        case .storageError:
            return "Failed to save image"
        case .analysisFailed:
            return "Failed to analyze image"
        }
    }
} 