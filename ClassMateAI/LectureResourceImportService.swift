import Foundation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class LectureResourceImportService: ObservableObject {
    enum ImportError: LocalizedError {
        case failedToReadFile
        case unsupportedType
        
        var errorDescription: String? {
            switch self {
            case .failedToReadFile:
                return "Unable to read the selected file."
            case .unsupportedType:
                return "This file type isn't supported yet."
            }
        }
    }
    
    @Published var lastError: String?
    
    func importDocument(from url: URL, lecture: Lecture, dataManager: DataManager) {
        print("Importing document from URL: \(url)")
        lastError = nil
        
        // Attempt to access security scoped resource, but don't fail if it returns false
        // (regular files like copies don't need this and will return false)
        let isSecurityScoped = url.startAccessingSecurityScopedResource()
        defer {
            if isSecurityScoped {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let data = try Data(contentsOf: url)
            let fileExtension = url.pathExtension.isEmpty ? "dat" : url.pathExtension
            let fileName = "\(UUID().uuidString).\(fileExtension)"
            let savedURL = try ResourceStorageService.shared.saveLectureResourceData(
                data,
                fileName: fileName,
                lectureId: lecture.id
            )
            
            let resource = LectureResource(
                lectureId: lecture.id,
                title: url.deletingPathExtension().lastPathComponent,
                fileName: fileName,
                type: LectureResource.type(for: fileExtension),
                source: .manualUpload,
                sizeInBytes: try savedURL.fileSize()
            )
            dataManager.addLectureResource(resource)
            print("Document imported successfully: \(resource.title)")
        } catch {
            print("Document import failed: \(error.localizedDescription)")
            lastError = error.localizedDescription
        }
    }
    
    func importScannedDocument(data: Data, lecture: Lecture, dataManager: DataManager, suggestedTitle: String) {
        print("Importing scanned document")
        lastError = nil
        do {
            let fileName = "\(UUID().uuidString).pdf"
            let savedURL = try ResourceStorageService.shared.saveLectureResourceData(
                data,
                fileName: fileName,
                lectureId: lecture.id
            )
            let resource = LectureResource(
                lectureId: lecture.id,
                title: suggestedTitle,
                fileName: fileName,
                type: .pdf,
                source: .scan,
                sizeInBytes: try savedURL.fileSize()
            )
            dataManager.addLectureResource(resource)
            print("Scanned document imported successfully: \(resource.title)")
        } catch {
            print("Scanned document import failed: \(error.localizedDescription)")
            lastError = error.localizedDescription
        }
    }
}

