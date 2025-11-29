import Foundation
import AVFoundation

class TimestampedTranscriptionService: ObservableObject {
    @Published var isTranscribing = false
    @Published var transcriptionProgress: Double = 0.0
    @Published var transcribedText = ""
    @Published var error: String?
    
    private let apiKey: String
    private let transcriptionURL = "https://api.openai.com/v1/audio/transcriptions"
    
    init() {
        self.apiKey = Config.openAIApiKey
    }
    
    func transcribeWithTimestamps(url: URL) async throws -> (String, [NotesTimestamp]) {
        await MainActor.run {
            isTranscribing = true
            transcriptionProgress = 0.0
            error = nil
        }
        
        defer {
            Task { @MainActor in
                isTranscribing = false
            }
        }
        
        print("TimestampedTranscriptionService: Starting timestamped transcription of file at \(url)")
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw TranscriptionError.fileNotFound
        }
        
        // Check file size
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        print("TimestampedTranscriptionService: File size: \(fileSize) bytes")
        
        if fileSize < 1000 {
            throw TranscriptionError.fileTooSmall
        }
        
        // Convert audio to required format if needed
        let processedURL = try await convertAudioToRequiredFormat(url: url)
        
        await MainActor.run {
            transcriptionProgress = 0.3
        }
        
        // Upload and transcribe with timestamps
        let (transcription, timestamps) = try await uploadAndTranscribeWithTimestamps(url: processedURL)
        
        await MainActor.run {
            transcriptionProgress = 1.0
            transcribedText = transcription
        }
        
        return (transcription, timestamps)
    }
    
    private func convertAudioToRequiredFormat(url: URL) async throws -> URL {
        // For now, return the original URL
        // In a full implementation, you might want to convert to mp3 if needed
        return url
    }
    
    private func uploadAndTranscribeWithTimestamps(url: URL) async throws -> (String, [NotesTimestamp]) {
        print("TimestampedTranscriptionService: Uploading and transcribing audio with timestamps")
        
        guard let apiURL = URL(string: transcriptionURL) else {
            throw TranscriptionError.invalidURL
        }
        
        // Create multipart form data
        let boundary = UUID().uuidString
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120.0 // 2 minutes timeout for large files
        
        var body = Data()
        
        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(url.lastPathComponent)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/mpeg\r\n\r\n".data(using: .utf8)!)
        
        let audioData = try Data(contentsOf: url)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add model parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)
        
        // Add language parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        body.append("en\r\n".data(using: .utf8)!)
        
        // Add response format for timestamps
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("verbose_json\r\n".data(using: .utf8)!)
        
        // Add prompt for better accuracy
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
        body.append("This is a lecture recording. Please transcribe it accurately, maintaining proper punctuation and sentence structure. Include academic terminology and proper nouns as spoken.\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        await MainActor.run {
            transcriptionProgress = 0.6
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TranscriptionError.invalidResponse
            }
            
            print("TimestampedTranscriptionService: HTTP Status: \(httpResponse.statusCode)")
            
            if !(200...299).contains(httpResponse.statusCode) {
                if let errorString = String(data: data, encoding: .utf8) {
                    print("TimestampedTranscriptionService: Error response: \(errorString)")
                }
                throw TranscriptionError.apiError("HTTP \(httpResponse.statusCode)")
            }
            
            // Parse the verbose JSON response
            let transcriptionResult = try parseVerboseJSONResponse(data: data)
            
            let trimmedTranscription = transcriptionResult.text.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedTranscription.isEmpty {
                throw TranscriptionError.noSpeechDetected
            }
            
            print("TimestampedTranscriptionService: Transcription successful - \(trimmedTranscription.count) characters")
            print("TimestampedTranscriptionService: Generated \(transcriptionResult.segments.count) timestamp segments")
            
            return (trimmedTranscription, transcriptionResult.segments)
            
        } catch {
            print("TimestampedTranscriptionService: Network error: \(error)")
            throw TranscriptionError.networkError(error.localizedDescription)
        }
    }
    
    private func parseVerboseJSONResponse(data: Data) throws -> (text: String, segments: [NotesTimestamp]) {
        struct WhisperResponse: Codable {
            let text: String
            let segments: [Segment]
        }
        
        struct Segment: Codable {
            let start: Double
            let end: Double
            let text: String
        }
        
        let response = try JSONDecoder().decode(WhisperResponse.self, from: data)
        
        // Convert segments to NotesTimestamp format
        var timestamps: [NotesTimestamp] = []
        var currentText = ""
        var currentStartIndex = 0
        
        for (index, segment) in response.segments.enumerated() {
            let segmentText = segment.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !segmentText.isEmpty {
                let endIndex = currentStartIndex + segmentText.count
                
                // Create a timestamp for this segment
                let timestamp = NotesTimestamp(
                    sectionTitle: "Segment \(index + 1)",
                    timestamp: segment.start,
                    startIndex: currentStartIndex,
                    endIndex: endIndex
                )
                timestamps.append(timestamp)
                
                currentText += segmentText + " "
                currentStartIndex = currentText.count
            }
        }
        
        // If no timestamps were created, create a default one
        if timestamps.isEmpty {
            let defaultTimestamp = NotesTimestamp(
                sectionTitle: "Lecture",
                timestamp: 0.0,
                startIndex: 0,
                endIndex: response.text.count
            )
            timestamps.append(defaultTimestamp)
        }
        
        print("TimestampedTranscriptionService: Created \(timestamps.count) timestamps")
        for (index, timestamp) in timestamps.enumerated() {
            print("TimestampedTranscriptionService: Timestamp \(index): \(timestamp.sectionTitle) at \(timestamp.timestamp)s")
        }
        
        return (response.text, timestamps)
    }
    
    func stopTranscription() {
        Task { @MainActor in
            isTranscribing = false
            transcriptionProgress = 0.0
        }
    }
    
    func reset() {
        Task { @MainActor in
            isTranscribing = false
            transcriptionProgress = 0.0
            transcribedText = ""
            error = nil
        }
    }
}

// Reuse the existing TranscriptionError enum
extension TimestampedTranscriptionService {
    enum TranscriptionError: Error, LocalizedError {
        case fileNotFound
        case fileTooSmall
        case invalidURL
        case conversionFailed
        case invalidResponse
        case apiError(String)
        case networkError(String)
        case noSpeechDetected
        
        var errorDescription: String? {
            switch self {
            case .fileNotFound:
                return "Audio file not found"
            case .fileTooSmall:
                return "Audio file is too small. Please ensure you have a valid recording."
            case .invalidURL:
                return "Invalid API URL"
            case .conversionFailed:
                return "Failed to convert audio format"
            case .invalidResponse:
                return "Invalid response from transcription service"
            case .apiError(let message):
                return "Transcription error: \(message)"
            case .networkError(let message):
                return "Network error: \(message)"
            case .noSpeechDetected:
                return "No speech detected in the recording. Please ensure the audio contains clear speech."
            }
        }
    }
} 