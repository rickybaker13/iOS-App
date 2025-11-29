import SwiftUI

struct LectureFilesListView: View {
    let lecture: Lecture
    @ObservedObject var dataManager: DataManager
    @Binding var lectureResourcePreview: ResourcePreviewItem?
    @Environment(\.dismiss) private var dismiss
    
    private var resources: [LectureResource] {
        dataManager.lectureResources(for: lecture.id)
    }
    
    var body: some View {
        NavigationView {
            List {
                if resources.isEmpty {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "doc")
                                .font(.system(size: 40))
                                .foregroundColor(.mateSecondary)
                            Text("No files uploaded yet")
                                .foregroundColor(.mateSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                    }
                } else {
                    ForEach(resources) { resource in
                        Button {
                            open(resource)
                        } label: {
                            HStack {
                                Image(systemName: resource.type.iconName)
                                    .foregroundColor(.matePrimary)
                                VStack(alignment: .leading) {
                                    Text(resource.title)
                                        .foregroundColor(.mateText)
                                    Text(resource.type.displayName)
                                        .font(.caption)
                                        .foregroundColor(.mateSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.mateSecondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Lecture Files")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func open(_ resource: LectureResource) {
        if let url = ResourceStorageService.shared.localFileURL(for: resource) {
            lectureResourcePreview = ResourcePreviewItem(url: url, title: resource.title)
        }
    }
}

