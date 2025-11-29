import Foundation
import Speech
import Combine

class SpeechRecognizer: NSObject, ObservableObject {
    @Published var transcribedText = ""
    @Published var isTranscribing = false
    @Published var error: String?
    @Published var transcriptionProgress: Double = 0.0
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    override init() {
        super.init()
        requestAuthorization()
    }
    
    private func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self?.error = nil
                    print("SpeechRecognizer: Speech recognition authorized")
                case .denied:
                    self?.error = "Speech recognition permission denied. Please enable it in Settings."
                    print("SpeechRecognizer: Speech recognition denied")
                case .restricted:
                    self?.error = "Speech recognition is restricted on this device"
                    print("SpeechRecognizer: Speech recognition restricted")
                case .notDetermined:
                    self?.error = "Speech recognition not yet authorized"
                    print("SpeechRecognizer: Speech recognition not determined")
                @unknown default:
                    self?.error = "Unknown authorization status"
                    print("SpeechRecognizer: Speech recognition unknown status")
                }
            }
        }
    }
    
    func transcribeAudioFile(url: URL) {
        print("SpeechRecognizer: Starting transcription of file at \(url)")
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            error = "Speech recognition is not available on this device"
            print("SpeechRecognizer: Speech recognition not available")
            return
        }
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            error = "Audio file not found"
            print("SpeechRecognizer: Audio file not found at \(url)")
            return
        }
            
            isTranscribing = true
            transcribedText = ""
            error = nil
        transcriptionProgress = 0.0
            
            let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = true // Enable partial results for better feedback
        request.requiresOnDeviceRecognition = false // Use cloud for better accuracy
        
        // Add additional configuration for better recognition
        request.taskHint = .dictation // Optimize for dictation/lecture content
        request.contextualStrings = ["lecture", "class", "subject", "topic", "chapter", "section", "example", "therefore", "however", "because", "important", "key", "concept", "definition", "theory", "method", "process", "system", "analysis", "research", "study", "data", "result", "conclusion"]
        
        print("SpeechRecognizer: Created recognition request for full file transcription")
        print("SpeechRecognizer: Using cloud recognition with dictation optimization")
        print("SpeechRecognizer: Partial results enabled: \(request.shouldReportPartialResults)")
            
            recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
                guard let self = self else { return }
                
                if let error = error {
                print("SpeechRecognizer: Error during transcription - \(error.localizedDescription)")
                print("SpeechRecognizer: Error details - \(error)")
                
                // Try fallback to on-device recognition if cloud fails
                if !request.requiresOnDeviceRecognition {
                    print("SpeechRecognizer: Trying fallback to on-device recognition")
                    self.tryOnDeviceRecognition(url: url)
                    return
                }
                
                DispatchQueue.main.async {
                    self.error = self.formatError(error)
                    self.isTranscribing = false
                    self.transcriptionProgress = 0.0
                }
                return
            }
            
            if let result = result {
                let rawText = result.bestTranscription.formattedString
                print("SpeechRecognizer: Raw transcription received - \(rawText.count) characters")
                print("SpeechRecognizer: Raw text preview: '\(String(rawText.prefix(200)))'")
                print("SpeechRecognizer: Is final: \(result.isFinal)")
                
                let processedText = self.processTranscription(rawText)
                
                DispatchQueue.main.async {
                    self.transcribedText = processedText
                    print("SpeechRecognizer: Processed transcription - \(processedText.count) characters")
                    
                    if processedText.count > 0 {
                        print("SpeechRecognizer: Processed text preview: '\(String(processedText.prefix(200)))'")
                    } else {
                        print("SpeechRecognizer: WARNING - Processed text is empty after processing")
                    }
                    
                    if result.isFinal {
                        self.transcriptionProgress = 1.0
                        self.isTranscribing = false
                        print("SpeechRecognizer: Final transcription completed - \(processedText.count) characters")
                        
                        if processedText.isEmpty {
                            print("SpeechRecognizer: WARNING - Final transcription is empty")
                        }
                    } else {
                        // Update progress for partial results - more aggressive progress
                        let progress = min(0.95, Double(processedText.count) / 500.0) // More sensitive to text length
                        self.transcriptionProgress = progress
                        print("SpeechRecognizer: Progress updated to \(progress * 100)%")
                    }
                }
            } else {
                print("SpeechRecognizer: No result and no error - this might indicate no speech detected")
                DispatchQueue.main.async {
                    self.error = "No speech detected in the recording. Please ensure the audio contains clear speech."
                    self.isTranscribing = false
                    self.transcriptionProgress = 0.0
                }
            }
        }
        
        // Set a completion timer to force completion if needed
        DispatchQueue.main.asyncAfter(deadline: .now() + 240) { // 4 minutes
            if self.isTranscribing && !self.transcribedText.isEmpty {
                print("SpeechRecognizer: Forcing completion after timeout")
                self.forceCompletion()
            }
        }
    }
    
    private func tryOnDeviceRecognition(url: URL) {
        print("SpeechRecognizer: Attempting on-device recognition")
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true
        request.taskHint = .dictation
        
        print("SpeechRecognizer: On-device recognition configured with partial results enabled")
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                print("SpeechRecognizer: On-device recognition also failed - \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.error = self.formatError(error)
                    self.isTranscribing = false
                    self.transcriptionProgress = 0.0
                }
                    return
                }
                
                if let result = result {
                let rawText = result.bestTranscription.formattedString
                print("SpeechRecognizer: On-device transcription received - \(rawText.count) characters")
                print("SpeechRecognizer: On-device is final: \(result.isFinal)")
                
                let processedText = self.processTranscription(rawText)
                
                DispatchQueue.main.async {
                    self.transcribedText = processedText
                    
                    if result.isFinal {
                        self.transcriptionProgress = 1.0
                        self.isTranscribing = false
                        print("SpeechRecognizer: On-device transcription completed - \(processedText.count) characters")
                    } else {
                        // Update progress for partial results - more aggressive progress
                        let progress = min(0.95, Double(processedText.count) / 500.0)
                        self.transcriptionProgress = progress
                        print("SpeechRecognizer: On-device progress updated to \(progress * 100)%")
                    }
                }
            }
        }
        
        // Set a completion timer for on-device recognition too
        DispatchQueue.main.asyncAfter(deadline: .now() + 240) { // 4 minutes
            if self.isTranscribing && !self.transcribedText.isEmpty {
                print("SpeechRecognizer: Forcing on-device completion after timeout")
                self.forceCompletion()
            }
        }
    }
    
    private func processTranscription(_ text: String) -> String {
        var processed = text
        
        // Remove excessive whitespace
        processed = processed.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Only remove very obvious filler words, be more conservative
        processed = processed
            .replacingOccurrences(of: " um ", with: " ")
            .replacingOccurrences(of: " uh ", with: " ")
        
        // Fix punctuation spacing
        processed = processed
            .replacingOccurrences(of: " ,", with: ",")
            .replacingOccurrences(of: " .", with: ".")
            .replacingOccurrences(of: " ?", with: "?")
            .replacingOccurrences(of: " !", with: "!")
            .replacingOccurrences(of: " ;", with: ";")
            .replacingOccurrences(of: " :", with: ":")
        
        // Add missing punctuation at sentence endings
        processed = addMissingPunctuation(processed)
        
        // Capitalize sentences
        processed = capitalizeSentences(processed)
        
        // Remove leading/trailing whitespace
        processed = processed.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return processed
    }
    
    private func addMissingPunctuation(_ text: String) -> String {
        var processed = text
        
        // Split into sentences and add punctuation if missing
        let sentences = processed.components(separatedBy: [".", "!", "?"])
        var result = ""
        
        for (index, sentence) in sentences.enumerated() {
            let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                result += trimmed
                
                // Add punctuation if missing at the end
                if !trimmed.hasSuffix(".") && !trimmed.hasSuffix("!") && !trimmed.hasSuffix("?") {
                    // Try to determine if it should end with a period, question mark, or exclamation
                    let lowercased = trimmed.lowercased()
                    if lowercased.contains("what") || lowercased.contains("how") || lowercased.contains("why") || 
                       lowercased.contains("when") || lowercased.contains("where") || lowercased.contains("who") {
                        result += "?"
                    } else if lowercased.contains("amazing") || lowercased.contains("incredible") || 
                              lowercased.contains("wow") || lowercased.contains("fantastic") {
                        result += "!"
                    } else {
                        result += "."
                    }
                }
                
                if index < sentences.count - 1 {
                    result += " "
                }
            }
        }
        
        return result
    }
    
    private func capitalizeSentences(_ text: String) -> String {
        let sentences = text.components(separatedBy: [".", "!", "?"])
        var result = ""
        
        for (index, sentence) in sentences.enumerated() {
            let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                let capitalized = trimmed.prefix(1).uppercased() + trimmed.dropFirst()
                result += capitalized
                
                // Add back the punctuation
                if index < sentences.count - 1 {
                    let originalText = text as NSString
                    let sentenceRange = originalText.range(of: sentence)
                    if sentenceRange.location + sentenceRange.length < originalText.length {
                        let nextChar = originalText.substring(with: NSRange(location: sentenceRange.location + sentenceRange.length, length: 1))
                        if [".", "!", "?"].contains(nextChar) {
                            result += nextChar
                        }
                    }
                }
                result += " "
            }
        }
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func formatError(_ error: Error) -> String {
        // Check for specific speech recognition error codes
        let errorDescription = error.localizedDescription.lowercased()
        
        if errorDescription.contains("audio engine") {
            return "Audio engine error. Please try again."
        } else if errorDescription.contains("audio format") || errorDescription.contains("format") {
            return "Invalid audio format. Please check your recording."
        } else if errorDescription.contains("authorized") || errorDescription.contains("permission") {
            return "Speech recognition not authorized. Please enable it in Settings."
        } else if errorDescription.contains("recognition failed") {
            return "Recognition failed. Please try again."
        } else if errorDescription.contains("speech not recognized") {
            return "Speech not recognized. Please speak clearly and try again."
        } else if errorDescription.contains("network") {
            return "Network error. Please check your internet connection."
        } else if errorDescription.contains("server") {
            return "Server error. Please try again later."
        } else if errorDescription.contains("timeout") {
            return "Transcription timed out. Please try again."
        } else if errorDescription.contains("cancelled") {
            return "Transcription was cancelled."
        } else if errorDescription.contains("no speech") {
            return "No speech detected in the recording. Please ensure the audio contains clear speech."
        } else {
            print("SpeechRecognizer: Unknown error - \(error.localizedDescription)")
            return "Transcription error: \(error.localizedDescription)"
        }
    }
    
    func stopTranscription() {
        recognitionTask?.cancel()
        recognitionTask = nil
        isTranscribing = false
        transcriptionProgress = 0.0
        print("SpeechRecognizer: Transcription stopped")
    }
    
    func reset() {
        transcribedText = ""
        error = nil
        transcriptionProgress = 0.0
        stopTranscription()
    }
    
    func forceCompletion() {
        print("SpeechRecognizer: Forcing transcription completion")
        DispatchQueue.main.async {
            self.transcriptionProgress = 1.0
            self.isTranscribing = false
            print("SpeechRecognizer: Forced completion with \(self.transcribedText.count) characters")
        }
    }
} 