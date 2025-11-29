import SwiftUI

struct CanvasDashboardView: View {
    @EnvironmentObject private var dataManager: DataManager
    let courses: [CanvasCourse]
    @ObservedObject var syncManager: CanvasSyncManager
    
    var refreshAction: () -> Void
    var onCourseSelected: (CanvasCourse) -> Void
    
    var body: some View {
        ZStack {
            Color.mateBackground.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Courses Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Courses")
                            .font(.appHeadline)
                            .padding(.horizontal, 4)
                        
                        if courses.isEmpty {
                            emptyStateCard(message: "No courses available. Try syncing Canvas.")
                        } else {
                            // Use LazyVGrid for a 2-column layout for courses if desired, or just a stack
                            // Sticking to stack for now for consistency with cards
                            VStack(spacing: 12) {
                                ForEach(courses) { course in
                                    Button {
                                        onCourseSelected(course)
                                    } label: {
                                        CanvasCourseCard(course: course)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Upcoming Work Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Upcoming Work")
                                .font(.appHeadline)
                            Spacer()
                            if syncManager.isSyncing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        .padding(.horizontal, 4)
                        
                        if filteredPlannerItems.isEmpty {
                             emptyStateCard(message: "No upcoming assignments due soon.")
                        } else {
                            VStack(spacing: 12) {
                                ForEach(filteredPlannerItems) { item in
                                    CanvasPlannerCard(item: item)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Canvas Planner")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { refreshAction() }) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.matePrimary)
                }
            }
        }
    }
    
    private func emptyStateCard(message: String) -> some View {
        Text(message)
            .font(.appBody)
            .foregroundColor(.mateSecondary)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.mateCardBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

private struct CanvasCourseCard: View {
    let course: CanvasCourse
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(course.name)
                    .font(.appBodyMedium)
                    .foregroundColor(.mateText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.mateSecondary.opacity(0.7))
        }
        .padding(16)
        .background(Color.mateCardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

private struct CanvasPlannerCard: View {
    let item: CanvasPlannerItem
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon Column
            Image(systemName: item.type.iconName)
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(item.isOverdue ? Color.mateRed : Color.matePrimary)
                .clipShape(Circle())
                .shadow(color: (item.isOverdue ? Color.mateRed : Color.matePrimary).opacity(0.3), radius: 5, x: 0, y: 3)
            
            // Content Column
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.appBodyMedium)
                    .foregroundColor(.mateText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if let courseName = item.courseName {
                    Text(courseName)
                        .font(.appCaption)
                        .foregroundColor(.mateSecondary)
                        .lineLimit(1)
                }
                
                if let dueAt = item.dueAt {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                        Text("Due \(dateFormatter.string(from: dueAt))")
                            .font(.appCaption)
                    }
                    .foregroundColor(item.isOverdue ? .mateRed : .mateSecondary)
                    .padding(.top, 2)
                }
            }
            
            Spacer()
            
            if item.submitted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.mateGreen)
            }
        }
        .padding(16)
        .background(Color.mateCardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

private extension CanvasDashboardView {
    var filteredPlannerItems: [CanvasPlannerItem] {
        dataManager.canvasPlannerItems.filter { item in
            !dataManager.isCourseHidden(item.courseId)
        }
    }
}
