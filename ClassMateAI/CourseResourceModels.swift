import Foundation

struct CourseResource: Identifiable, Codable, Hashable {
    enum ResourceType: String, Codable, CaseIterable {
        case pdf
        case slideDeck
        case document
        case spreadsheet
        case image
        case audio
        case link
        case other
        
        var displayName: String {
            switch self {
            case .pdf: return "PDF"
            case .slideDeck: return "Slides"
            case .document: return "Document"
            case .spreadsheet: return "Spreadsheet"
            case .image: return "Image"
            case .audio: return "Audio"
            case .link: return "Link"
            case .other: return "Resource"
            }
        }
    }
    
    enum SourceType: String, Codable {
        case canvasAttachment
        case canvasLink
        case manualUpload
    }
    
    let id: UUID
    let courseId: Int
    let assignmentId: Int?
    var title: String
    var fileName: String?
    var remoteURL: URL?
    var thumbnailFileName: String?
    var type: ResourceType
    var source: SourceType
    var sizeInBytes: Int64?
    var tags: [String]
    var importedAt: Date
    var lastAccessedAt: Date?
    var textPreview: String?
    
    init(
        id: UUID = UUID(),
        courseId: Int,
        assignmentId: Int?,
        title: String,
        fileName: String? = nil,
        remoteURL: URL? = nil,
        thumbnailFileName: String? = nil,
        type: ResourceType,
        source: SourceType,
        sizeInBytes: Int64? = nil,
        tags: [String] = [],
        importedAt: Date = Date(),
        lastAccessedAt: Date? = nil,
        textPreview: String? = nil
    ) {
        self.id = id
        self.courseId = courseId
        self.assignmentId = assignmentId
        self.title = title
        self.fileName = fileName
        self.remoteURL = remoteURL
        self.thumbnailFileName = thumbnailFileName
        self.type = type
        self.source = source
        self.sizeInBytes = sizeInBytes
        self.tags = tags
        self.importedAt = importedAt
        self.lastAccessedAt = lastAccessedAt
        self.textPreview = textPreview
    }
}

extension CourseResource {
    var hasLocalFile: Bool {
        fileName != nil
    }
    
    static func displayFormatter(for size: Int64?) -> String {
        guard let size else { return "Unknown size" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: size)
    }
}

extension CourseResource.ResourceType {
    static func from(contentType: String?, fileExtension: String?) -> CourseResource.ResourceType {
        if let contentType {
            if contentType.contains("pdf") { return .pdf }
            if contentType.contains("presentation") { return .slideDeck }
            if contentType.contains("vnd.google-apps.presentation") { return .slideDeck }
            if contentType.contains("spreadsheet") { return .spreadsheet }
            if contentType.contains("excel") { return .spreadsheet }
            if contentType.contains("word") || contentType.contains("document") { return .document }
            if contentType.contains("image") { return .image }
            if contentType.contains("audio") { return .audio }
        }
        
        if let ext = fileExtension?.lowercased() {
            switch ext {
            case "pdf": return .pdf
            case "ppt", "pptx", "key", "pps": return .slideDeck
            case "doc", "docx", "rtf", "txt": return .document
            case "xls", "xlsx", "csv": return .spreadsheet
            case "jpg", "jpeg", "png", "gif", "heic": return .image
            case "mp3", "m4a", "wav": return .audio
            default: break
            }
        }
        
        return .other
    }
}

