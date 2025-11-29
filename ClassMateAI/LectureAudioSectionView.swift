import SwiftUI

struct LectureAudioSectionView: View {
    let lecture: Lecture
    @ObservedObject var audioPlayer: AudioPlayer
    
    var body: some View {
        VStack(spacing: 15) {
            // Main Play/Pause Button
            HStack {
                Button(action: {
                    if audioPlayer.isPlaying {
                        audioPlayer.pause()
                    } else if let url = lecture.recordingURL {
                        print("LectureAudioSection: Attempting to play audio from URL: \(url)")
                        audioPlayer.play(url: url)
                    }
                }) {
                    Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.matePrimary)
                }
                .disabled(lecture.recordingURL == nil)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(audioPlayer.formatTime(audioPlayer.currentTime))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.mateText)
                    
                    Text(audioPlayer.formatDuration())
                        .font(.subheadline)
                        .foregroundColor(.mateSecondary)
                }
                
                Spacer()
                
                // Skip Backward
                Button(action: { audioPlayer.skipBackward() }) {
                    Image(systemName: "gobackward.10")
                        .font(.system(size: 24))
                        .foregroundColor(.mateSecondary)
                }
                .disabled(lecture.recordingURL == nil)
                
                // Skip Forward
                Button(action: { audioPlayer.skipForward() }) {
                    Image(systemName: "goforward.10")
                        .font(.system(size: 24))
                        .foregroundColor(.mateSecondary)
                }
                .disabled(lecture.recordingURL == nil)
            }
            
            // Progress Bar
            if audioPlayer.duration > 0 {
                ProgressBarView(audioPlayer: audioPlayer)
            }
            
            if let error = audioPlayer.error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color.mateSecondary.opacity(0.1))
        .cornerRadius(12)
    }
}

private struct ProgressBarView: View {
    @ObservedObject var audioPlayer: AudioPlayer
    
    var body: some View {
        VStack(spacing: 8) {
            // Seekable Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Rectangle()
                        .fill(Color.mateSecondary.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    // Progress track
                    Rectangle()
                        .fill(Color.matePrimary)
                        .frame(width: geometry.size.width * (audioPlayer.currentTime / audioPlayer.duration), height: 4)
                        .cornerRadius(2)
                    
                    // Seek handle
                    Circle()
                        .fill(Color.matePrimary)
                        .frame(width: 16, height: 16)
                        .offset(x: geometry.size.width * (audioPlayer.currentTime / audioPlayer.duration) - 8)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let newPosition = value.location.x / geometry.size.width
                                    audioPlayer.seek(to: newPosition * audioPlayer.duration)
                                }
                        )
                }
            }
            .frame(height: 20)
            
            // Time labels
            HStack {
                Text(audioPlayer.formatTime(audioPlayer.currentTime))
                    .font(.caption)
                    .foregroundColor(.mateSecondary)
                Spacer()
                Text(audioPlayer.formatTime(audioPlayer.duration))
                    .font(.caption)
                    .foregroundColor(.mateSecondary)
            }
        }
    }
}
