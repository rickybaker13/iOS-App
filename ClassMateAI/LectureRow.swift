import SwiftUI

public struct LectureRow: View {
    let lecture: Lecture
    
    public init(lecture: Lecture) {
        self.lecture = lecture
    }
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(lecture.title)
                    .font(.headline)
                    .foregroundColor(.mateText)
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.mateSecondary)
                    Text(lecture.date, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.mateSecondary)
                    
                    Image(systemName: "clock")
                        .foregroundColor(.mateSecondary)
                    Text(formatDuration(lecture.duration))
                        .font(.subheadline)
                        .foregroundColor(.mateSecondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.mateSecondary)
        }
        .padding(.vertical, 4)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        return "\(minutes) min"
    }
} 