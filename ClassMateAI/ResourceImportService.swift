import Foundation
import SwiftUI

@MainActor
final class ResourceImportService: ObservableObject {
    enum ImportError: LocalizedError {
        case missingURL
        case downloadFailed(String)
        case invalidData
        
        var errorDescription: String? {
            switch self {
            case .missingURL:
                return "Resource URL is missing."
            case .downloadFailed(let message):
                return "Download failed: \(message)"
            case .invalidData:
                return "Downloaded data is invalid."
            }
        }
    }
    
    @Published private(set) var downloadProgress: [Int: Double] = [:]
    @Published private(set) var activeDownloads: Set<Int> = []
    @Published private(set) var lastError: String?
    
    func importAttachment(
        _ attachment: CanvasAssignmentAttachment,
        assignment: CanvasAssignment,
        course: CanvasCourse,
        dataManager: DataManager
    ) async {
        guard let url = attachment.url else {
            lastError = ImportError.missingURL.localizedDescription
            return
        }
        
        activeDownloads.insert(attachment.id)
        downloadProgress[attachment.id] = 0
        lastError = nil
        
        do {
            var request = URLRequest(url: url)
            request.setValue("Bearer \(Config.canvasAccessToken)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw ImportError.downloadFailed("HTTP \( (response as? HTTPURLResponse)?.statusCode ?? -1)")
            }
            
            guard !data.isEmpty else {
                throw ImportError.invalidData
            }
            
            let fileExtension = attachment.displayName?.components(separatedBy: ".").last ?? "dat"
            let sanitizedName = sanitize(fileName: attachment.displayName ?? "resource.\(fileExtension)")
            let fileName = "\(attachment.id)-\(sanitizedName)"
            
            let savedURL = try ResourceStorageService.shared.saveResourceData(data, fileName: fileName, courseId: course.id)
            
            let resourceType = CourseResource.ResourceType.from(
                contentType: attachment.contentType,
                fileExtension: savedURL.pathExtension
            )
            
            let size = try? savedURL.fileSize()
            
            let resource = CourseResource(
                courseId: course.id,
                assignmentId: assignment.id,
                title: attachment.displayName ?? assignment.name,
                fileName: fileName,
                remoteURL: attachment.url,
                type: resourceType,
                source: .canvasAttachment,
                sizeInBytes: size ?? Int64(data.count),
                tags: [course.name, assignment.name],
                textPreview: assignment.descriptionText.isEmpty ? nil : assignment.descriptionText
            )
            
            dataManager.addCourseResource(resource)
            downloadProgress[attachment.id] = 1.0
        } catch {
            lastError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            downloadProgress[attachment.id] = nil
        }
        
        activeDownloads.remove(attachment.id)
    }
    
    func importExternalLink(
        url: URL,
        title: String,
        assignment: CanvasAssignment,
        course: CanvasCourse,
        dataManager: DataManager,
        type: CourseResource.ResourceType = .slideDeck
    ) {
        let resource = CourseResource(
            courseId: course.id,
            assignmentId: assignment.id,
            title: title,
            remoteURL: url,
            type: type,
            source: .canvasLink,
            tags: [course.name, assignment.name],
            textPreview: assignment.descriptionText.isEmpty ? nil : assignment.descriptionText
        )
        dataManager.addCourseResource(resource)
    }
    
    private func sanitize(fileName: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        return fileName
            .components(separatedBy: invalidCharacters)
            .joined(separator: "_")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension URL {
    func fileSize() throws -> Int64 {
        let values = try resourceValues(forKeys: [.fileSizeKey])
        return Int64(values.fileSize ?? 0)
    }
}

