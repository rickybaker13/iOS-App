import Foundation

final class ResourceStorageService {
    static let shared = ResourceStorageService()
    
    private init() {}
    
    private var courseBaseDirectory: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent("CourseResources", isDirectory: true)
    }
    
    private var lectureBaseDirectory: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent("LectureResources", isDirectory: true)
    }
    
    private func directory(for courseId: Int) -> URL {
        courseBaseDirectory.appendingPathComponent("course-\(courseId)", isDirectory: true)
    }
    
    private func lectureDirectory(for lectureId: UUID) -> URL {
        lectureBaseDirectory.appendingPathComponent("lecture-\(lectureId.uuidString)", isDirectory: true)
    }
    
    func localFileURL(for resource: CourseResource) -> URL? {
        guard let fileName = resource.fileName else { return nil }
        return directory(for: resource.courseId).appendingPathComponent(fileName)
    }
    
    func thumbnailURL(for resource: CourseResource) -> URL? {
        guard let fileName = resource.thumbnailFileName else { return nil }
        return directory(for: resource.courseId).appendingPathComponent("thumb-\(fileName)")
    }
    
    func saveResourceData(_ data: Data, fileName: String, courseId: Int) throws -> URL {
        let dir = directory(for: courseId)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let destination = dir.appendingPathComponent(fileName)
        try data.write(to: destination, options: .atomic)
        return destination
    }
    
    func deleteResourceFiles(for resource: CourseResource) {
        if let fileURL = localFileURL(for: resource) {
            try? FileManager.default.removeItem(at: fileURL)
        }
        if let thumbURL = thumbnailURL(for: resource) {
            try? FileManager.default.removeItem(at: thumbURL)
        }
    }
    
    func clearAllResources() {
        try? FileManager.default.removeItem(at: courseBaseDirectory)
        try? FileManager.default.removeItem(at: lectureBaseDirectory)
    }
    
    // MARK: - Lecture Resources
    
    func localFileURL(for resource: LectureResource) -> URL? {
        guard let fileName = resource.fileName else { return nil }
        return lectureDirectory(for: resource.lectureId).appendingPathComponent(fileName)
    }
    
    func saveLectureResourceData(_ data: Data, fileName: String, lectureId: UUID) throws -> URL {
        let dir = lectureDirectory(for: lectureId)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let destination = dir.appendingPathComponent(fileName)
        try data.write(to: destination, options: .atomic)
        return destination
    }
    
    func deleteLectureResourceFiles(for resource: LectureResource) {
        if let fileURL = localFileURL(for: resource) {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
}

