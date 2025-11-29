import SwiftUI

struct LectureActionsSectionView: View {
    let lecture: Lecture
    @Binding var showingTranscriptionAlert: Bool
    @Binding var showingDeleteAlert: Bool
    @Binding var showingMoveAlert: Bool
    @Binding var showingCustomTriggers: Bool
    @Binding var showingVisualCapture: Bool
    @Binding var showingVisualGallery: Bool
    @Binding var showingDocumentPicker: Bool
    @Binding var showingDocumentScanner: Bool
    @Binding var showingAIQuestion: Bool
    let startTranscription: () -> Void
    let deleteLecture: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Actions")
                .font(.title2)
                .foregroundColor(.mateText)

            HStack(spacing: 12) {
                SectionActionButton(
                    title: "Ask AI",
                    icon: "sparkles",
                    color: .matePrimary,
                    action: { showingAIQuestion = true }
                )

                SectionActionButton(
                    title: "Start Transcription",
                    icon: "waveform",
                    color: .matePrimary,
                    action: { showingTranscriptionAlert = true }
                )
            }

            HStack(spacing: 12) {
                SectionActionButton(
                    title: "Delete Lecture",
                    icon: "trash",
                    color: .red,
                    action: { showingDeleteAlert = true }
                )

                SectionActionButton(
                    title: "Move Lecture",
                    icon: "folder",
                    color: .matePrimary,
                    action: { showingMoveAlert = true }
                )
            }

            HStack(spacing: 12) {
                SectionActionButton(
                    title: "Custom Triggers",
                    icon: "list.bullet",
                    color: .matePrimary,
                    action: { showingCustomTriggers = true }
                )

                SectionActionButton(
                    title: "Capture Visual",
                    icon: "camera",
                    color: .matePrimary,
                    action: { showingVisualCapture = true }
                )
            }

            HStack(spacing: 12) {
                SectionActionButton(
                    title: "Upload Document",
                    icon: "doc",
                    color: .matePrimary,
                    action: {
                        print("=== UPLOAD DOCUMENT BUTTON TAPPED ===")
                        showingDocumentPicker = true
                    }
                )

                SectionActionButton(
                    title: "Scan Document",
                    icon: "doc.viewfinder",
                    color: .matePrimary,
                    action: {
                        print("=== SCAN DOCUMENT BUTTON TAPPED ===")
                        showingDocumentScanner = true
                    }
                )
            }
        }
        .padding()
        .background(Color.mateSecondary.opacity(0.1))
        .cornerRadius(12)
    }
}

private struct SectionActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.8))
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
}
