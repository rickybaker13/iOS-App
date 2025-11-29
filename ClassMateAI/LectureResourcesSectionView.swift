import SwiftUI

struct LectureResourcesSectionView: View {
    let lecture: Lecture
    @ObservedObject var dataManager: DataManager
    @Binding var lectureResourcePreview: ResourcePreviewItem?
    @Binding var showingLectureFilesList: Bool

    var body: some View {
        let resources = self.resources

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Lecture Files")
                    .font(.title2)
                    .foregroundColor(.mateText)

                Spacer()

                if !resources.isEmpty {
                    Button(action: { showingLectureFilesList = true }) {
                        Text("View All")
                            .font(.subheadline)
                            .foregroundColor(.matePrimary)
                    }
                    .buttonStyle(.plain)
                }
            }

            let resources = self.resources

            if resources.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc")
                        .font(.system(size: 32))
                        .foregroundColor(.mateSecondary)

                    Text("No files uploaded yet")
                        .font(.subheadline)
                        .foregroundColor(.mateSecondary)

                    Text("Upload documents or scan notes to keep everything organized")
                        .font(.caption)
                        .foregroundColor(.mateSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .background(Color.white.opacity(0.5))
                .cornerRadius(8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(resources) { resource in
                            ResourceThumbnailView(
                                resource: resource,
                                onTap: {
                                    if let url = ResourceStorageService.shared.localFileURL(for: resource) {
                                        lectureResourcePreview = ResourcePreviewItem(url: url, title: resource.title)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .frame(height: 100)
            }
        }
        .padding()
        .background(Color.mateSecondary.opacity(0.1))
        .cornerRadius(12)
    }

    private var resources: [LectureResource] {
        dataManager.lectureResources(for: lecture.id)
    }
}

private struct ResourceThumbnailView: View {
    let resource: LectureResource
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 80, height: 60)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)

                    Image(systemName: resource.type.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(.matePrimary)
                }

                Text(resource.title)
                    .font(.caption)
                    .foregroundColor(.mateText)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 80)
            }
        }
    }
}
