import SwiftUI

struct ImportantInfoView: View {
    let lecture: Lecture
    @EnvironmentObject var dataManager: DataManager
    
    var importantInfo: [ImportantInfo] {
        dataManager.getImportantInfo(for: lecture.id)
    }
    
    var body: some View {
        List {
            ForEach(importantInfo) { info in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: iconName(for: info.type))
                            .foregroundColor(.matePrimary)
                        Text(info.type.rawValue.capitalized)
                            .font(.headline)
                            .foregroundColor(.matePrimary)
                    }
                    
                    Text(info.text)
                        .font(.body)
                    
                    Text("Source: \(info.source)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(info.timestamp, style: .date)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Important Information")
    }
    
    private func iconName(for type: ImportantInfo.InfoType) -> String {
        switch type {
        case .homework:
            return "book.fill"
        case .test:
            return "checkmark.circle.fill"
        case .quiz:
            return "questionmark.circle.fill"
        case .custom:
            return "star.fill"
        }
    }
} 