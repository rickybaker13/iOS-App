import SwiftUI

struct LectureMaterialsSectionView: View {
    let lecture: Lecture
    @ObservedObject var dataManager: DataManager
    @Binding var showingVisualGallery: Bool
    @Binding var showingLectureFilesList: Bool
    @Binding var showingNotesView: Bool
    @Binding var showingOutlineView: Bool
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Lecture Materials")
                .font(.title2)
                .foregroundColor(.mateText)
            
            LazyVGrid(columns: columns, spacing: 12) {
                materialButton(
                    title: "Visuals",
                    subtitle: countLabel(count: visualCount, item: "photo"),
                    icon: "photo.on.rectangle",
                    color: .matePrimary.opacity(0.15)
                ) {
                    showingVisualGallery = true
                }
                .disabled(visualCount == 0)
                .opacity(visualCount == 0 ? 0.4 : 1)
                
                materialButton(
                    title: "Files",
                    subtitle: countLabel(count: fileCount, item: "file"),
                    icon: "doc.on.doc",
                    color: .mateSecondary.opacity(0.2)
                ) {
                    showingLectureFilesList = true
                }
                .disabled(fileCount == 0)
                .opacity(fileCount == 0 ? 0.4 : 1)
                
                materialButton(
                    title: "Notes",
                    subtitle: lecture.notes.isEmpty ? "Not generated" : "Ready to review",
                    icon: "doc.text",
                    color: .matePrimary.opacity(0.15)
                ) {
                    showingNotesView = true
                }
                .disabled(lecture.notes.isEmpty)
                .opacity(lecture.notes.isEmpty ? 0.4 : 1)
                
                materialButton(
                    title: "Outline",
                    subtitle: lecture.outline.isEmpty ? "Not generated" : "Ready to review",
                    icon: "list.bullet.rectangle",
                    color: .mateSecondary.opacity(0.2)
                ) {
                    showingOutlineView = true
                }
                .disabled(lecture.outline.isEmpty)
                .opacity(lecture.outline.isEmpty ? 0.4 : 1)
            }
        }
        .padding()
        .background(Color.mateSecondary.opacity(0.08))
        .cornerRadius(12)
    }
    
    private var visualCount: Int {
        dataManager.getLectureImages(for: lecture.id).count
    }
    
    private var fileCount: Int {
        dataManager.lectureResources(for: lecture.id).count
    }
    
    @ViewBuilder
    private func materialButton(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(.matePrimary)
                    .padding(10)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.black)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.white.opacity(0.8))
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
    
    private func countLabel(count: Int, item: String) -> String {
        count == 0 ? "No \(item)s yet" : "\(count) \(item)\(count == 1 ? "" : "s")"
    }
}

