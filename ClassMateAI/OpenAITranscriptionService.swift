import Foundation
import AVFoundation

class OpenAITranscriptionService: ObservableObject {
    @Published var isTranscribing = false
    @Published var transcriptionProgress: Double = 0.0
    @Published var transcribedText = ""
    @Published var error: String?
    
    private let apiKey: String
    private let transcriptionURL = "https://api.openai.com/v1/audio/transcriptions"
    
    init() {
        self.apiKey = Config.openAIApiKey
    }
    
    func transcribeAudioFile(url: URL) async throws -> String {
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
        
        print("OpenAITranscriptionService: Starting transcription of file at \(url)")
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw TranscriptionError.fileNotFound
        }
        
        // Check file size
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        print("OpenAITranscriptionService: File size: \(fileSize) bytes")
        
        if fileSize < 1000 {
            throw TranscriptionError.fileTooSmall
        }
        
        // Convert audio to required format if needed
        let processedURL = try await convertAudioToRequiredFormat(url: url)
        
        await MainActor.run {
            transcriptionProgress = 0.3
        }
        
        // Upload and transcribe
        let transcription = try await uploadAndTranscribe(url: processedURL)
        
        await MainActor.run {
            transcriptionProgress = 1.0
            transcribedText = transcription
        }
        
        print("OpenAITranscriptionService: Transcription completed successfully")
        return transcription
    }
    
    private func convertAudioToRequiredFormat(url: URL) async throws -> URL {
        print("OpenAITranscriptionService: Converting audio format")
        
        // Check if already in required format (mp3, mp4, mpeg, mpga, m4a, wav, or webm)
        let fileExtension = url.pathExtension.lowercased()
        let supportedFormats = ["mp3", "mp4", "mpeg", "mpga", "m4a", "wav", "webm"]
        
        if supportedFormats.contains(fileExtension) {
            print("OpenAITranscriptionService: File already in supported format")
            return url
        }
        
        // Convert to mp3 format
        let outputURL = url.deletingPathExtension().appendingPathExtension("mp3")
        
        let asset = AVAsset(url: url)
        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough)
        
        guard let exportSession = exportSession else {
            throw TranscriptionError.conversionFailed
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp3
        
        await exportSession.export()
        
        if exportSession.status == .completed {
            print("OpenAITranscriptionService: Audio conversion completed")
            return outputURL
        } else {
            throw TranscriptionError.conversionFailed
        }
    }
    
    private func uploadAndTranscribe(url: URL) async throws -> String {
        print("OpenAITranscriptionService: Uploading and transcribing audio")
        
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
        
        // Add language parameter (optional, but helps accuracy)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        body.append("en\r\n".data(using: .utf8)!)
        
        // Add response format
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("text\r\n".data(using: .utf8)!)
        
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
            
            print("OpenAITranscriptionService: HTTP Status: \(httpResponse.statusCode)")
            
            if !(200...299).contains(httpResponse.statusCode) {
                if let errorString = String(data: data, encoding: .utf8) {
                    print("OpenAITranscriptionService: Error response: \(errorString)")
                }
                throw TranscriptionError.apiError("HTTP \(httpResponse.statusCode)")
            }
            
            guard let transcription = String(data: data, encoding: .utf8) else {
                throw TranscriptionError.invalidResponse
            }
            
            let trimmedTranscription = transcription.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedTranscription.isEmpty {
                throw TranscriptionError.noSpeechDetected
            }
            
            print("OpenAITranscriptionService: Transcription successful - \(trimmedTranscription.count) characters")
            return trimmedTranscription
            
        } catch {
            print("OpenAITranscriptionService: Network error: \(error)")
            throw TranscriptionError.networkError(error.localizedDescription)
        }
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