import Foundation
import Speech
import Combine

class SpeechRecognizer: NSObject, ObservableObject {
    @Published var transcribedText = ""
    @Published var isTranscribing = false
    @Published var error: String?
    
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
                    print("Speech recognition authorized")
                case .denied:
                    self?.error = "Speech recognition permission denied"
                    print("Speech recognition denied")
                case .restricted:
                    self?.error = "Speech recognition is restricted on this device"
                    print("Speech recognition restricted")
                case .notDetermined:
                    self?.error = "Speech recognition not yet authorized"
                    print("Speech recognition not determined")
                @unknown default:
                    self?.error = "Unknown authorization status"
                    print("Speech recognition unknown status")
                }
            }
        }
    }
    
    func transcribeAudioFile(url: URL) {
        print("SpeechRecognizer: Starting transcription of file at \(url)")
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            error = "Speech recognition is not available"
            print("SpeechRecognizer: Speech recognition not available")
            return
        }
        
        isTranscribing = true
        transcribedText = ""
        error = nil
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = true
        
        print("SpeechRecognizer: Created recognition request")
        
        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.error = error.localizedDescription
                self.isTranscribing = false
                print("SpeechRecognizer: Error during transcription - \(error.localizedDescription)")
                return
            }
            
            if let result = result {
                self.transcribedText = result.bestTranscription.formattedString
                print("SpeechRecognizer: Received transcription - \(self.transcribedText)")
                
                if result.isFinal {
                    self.isTranscribing = false
                    print("SpeechRecognizer: Transcription completed")
                }
            }
        }
    }
    
    func stopTranscription() {
        recognitionTask?.cancel()
        recognitionTask = nil
        isTranscribing = false
        print("SpeechRecognizer: Transcription stopped")
    }
} 