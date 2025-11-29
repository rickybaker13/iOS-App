import SwiftUI

struct LectureTranscriptionSectionView: View {
    let lecture: Lecture
    @ObservedObject var transcriptionService: OpenAITranscriptionService
    let startTranscription: () -> Void
    
    private var shouldShowSection: Bool {
        transcriptionService.isTranscribing
    }
    
    var body: some View {
        Group {
            if shouldShowSection {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Transcription")
                        .font(.title2)
                        .foregroundColor(.mateText)
                    
                    TranscriptionProgressSection(transcriptionService: transcriptionService)
                }
                .padding()
                .background(Color.mateSecondary.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
}

private struct TranscriptionProgressSection: View {
    @ObservedObject var transcriptionService: OpenAITranscriptionService
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView(value: transcriptionService.transcriptionProgress)
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)

            Text("Transcribing audio...")
                .font(.headline)
                .foregroundColor(.mateText)

            if transcriptionService.transcriptionProgress > 0 {
                Text("\(Int(transcriptionService.transcriptionProgress * 100))%")
                    .font(.caption)
                    .foregroundColor(.mateSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

// TranscriptionContentSection removed per design request (preview no longer shown)
