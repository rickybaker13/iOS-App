import SwiftUI

public struct SubjectRow: View {
    let subject: Subject
    
    public init(subject: Subject) {
        self.subject = subject
    }
    
    public var body: some View {
        HStack {
            Image(systemName: subject.icon)
                .font(.system(size: 24))
                .foregroundColor(.matePrimary)
                .frame(width: 40, height: 40)
                .background(Color.mateBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading) {
                Text(subject.name)
                    .font(.headline)
                    .foregroundColor(.mateText)
                Text("\(subject.lectures.count) Lectures")
                    .font(.subheadline)
                    .foregroundColor(.mateSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.mateSecondary)
        }
        .padding(.vertical, 4)
    }
} 