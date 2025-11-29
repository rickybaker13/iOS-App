import Foundation

struct LectureResource: Identifiable, Codable, Hashable {
    enum ResourceType: String, Codable, CaseIterable {
        case pdf
        case document
        case image
        case audio
        case link
        case other
        
        var displayName: String {
            switch self {
            case .pdf: return "PDF"
            case .document: return "Document"
            case .image: return "Image"
            case .audio: return "Audio"
            case .link: return "Link"
            case .other: return "Resource"
            }
        }

        var iconName: String {
            switch self {
            case .pdf: return "doc.richtext"
            case .document: return "doc.text"
            case .image: return "photo"
            case .audio: return "waveform"
            case .link: return "link"
            case .other: return "doc"
            }
        }
    }
    
    enum Source: String, Codable {
        case manualUpload
        case sharedUpload
        case scan
    }
    
    let id: UUID
    let lectureId: UUID
    var title: String
    var fileName: String?
    var remoteURL: URL?
    var type: ResourceType
    var source: Source
    var importedAt: Date
    var sizeInBytes: Int64?
    
    init(
        id: UUID = UUID(),
        lectureId: UUID,
        title: String,
        fileName: String? = nil,
        remoteURL: URL? = nil,
        type: ResourceType,
        source: Source,
        importedAt: Date = Date(),
        sizeInBytes: Int64? = nil
    ) {
        self.id = id
        self.lectureId = lectureId
        self.title = title
        self.fileName = fileName
        self.remoteURL = remoteURL
        self.type = type
        self.source = source
        self.importedAt = importedAt
        self.sizeInBytes = sizeInBytes
    }
}

extension LectureResource {
    var hasLocalFile: Bool {
        fileName != nil
    }
    
    static func type(for fileExtension: String) -> ResourceType {
        let ext = fileExtension.lowercased()
        switch ext {
        case "pdf": return .pdf
        case "doc", "docx", "rtf", "txt": return .document
        case "jpg", "jpeg", "png", "gif", "heic": return .image
        case "m4a", "mp3", "wav": return .audio
        default: return .other
        }
    }
}

