import SwiftUI

struct LectureVisualsSectionView: View {
    let lecture: Lecture
    @ObservedObject var dataManager: DataManager
    @Binding var showingVisualGallery: Bool
    
    var body: some View {
        let lectureImages = dataManager.getLectureImages(for: lecture.id)
        let imageCount = lectureImages.count
        
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Lecture Visuals")
                    .font(.title2)
                    .foregroundColor(.mateText)
                
                Spacer()
                
                Text("\(imageCount) photos")
                    .font(.subheadline)
                    .foregroundColor(.mateSecondary)
                
                if imageCount > 0 {
                    Button(action: {
                        print("LectureVisualsSectionView: View All tapped for \(lecture.title)")
                        showingVisualGallery = true
                    }) {
                        Text("View All")
                            .font(.subheadline)
                            .foregroundColor(.matePrimary)
                    }
                    .buttonStyle(.plain)
                }
            }
            
        if let firstImage = lectureImages.first {
            Button(action: {
                print("LectureVisualsSectionView: preview tapped for \(lecture.title)")
                showingVisualGallery = true
            }) {
                ZStack(alignment: .topTrailing) {
                    if let uiImage = loadImage(for: firstImage) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 120)
                            .clipped()
                            .cornerRadius(8)
                    } else {
                        Rectangle()
                            .fill(Color.mateSecondary.opacity(0.3))
                            .frame(height: 120)
                            .cornerRadius(8)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.mateSecondary)
                                    .font(.system(size: 32))
                            )
                    }
                    
                    if imageCount > 1 {
                        Text("+\(imageCount - 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(12)
                            .padding(8)
                    }
                }
            }
            .buttonStyle(.plain)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "camera")
                        .font(.system(size: 32))
                        .foregroundColor(.mateSecondary)
                    
                    Text("No visuals captured yet")
                        .font(.subheadline)
                        .foregroundColor(.mateSecondary)
                    
                    Text("Capture photos during lectures to reference later")
                        .font(.caption)
                        .foregroundColor(.mateSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .background(Color.white.opacity(0.5))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.mateSecondary.opacity(0.1))
        .cornerRadius(12)
    }

    private func loadImage(for lectureImage: LectureImage) -> UIImage? {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imagesPath = documents
            .appendingPathComponent("LectureImages")
            .appendingPathComponent(lectureImage.lectureId.uuidString)
            .appendingPathComponent(lectureImage.imageFileName)
        return UIImage(contentsOfFile: imagesPath.path)
    }
}
