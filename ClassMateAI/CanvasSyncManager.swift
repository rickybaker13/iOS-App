import Foundation

@MainActor
class CanvasSyncManager: ObservableObject {
    @Published private(set) var isSyncing = false
    @Published var lastError: String?
    
    private let apiClient: CanvasAPIClient
    private let reminderScheduler: CanvasReminderScheduler
    
    init(
        apiClient: CanvasAPIClient = CanvasAPIClient(),
        reminderScheduler: CanvasReminderScheduler = CanvasReminderScheduler()
    ) {
        self.apiClient = apiClient
        self.reminderScheduler = reminderScheduler
    }
    
    func sync(dataManager: DataManager) async {
        guard !isSyncing else { return }
        isSyncing = true
        lastError = nil
        
        do {
            async let coursesTask = apiClient.fetchCourses(limit: 15)
            async let plannerTask = apiClient.fetchPlannerItems(daysAhead: 30)
            let (courses, plannerItems) = try await (coursesTask, plannerTask)
            
            dataManager.setCanvasCourses(courses)
            dataManager.setCanvasPlannerItems(plannerItems)
            dataManager.updateCanvasLastSync(Date())
            
            if dataManager.canvasRemindersEnabled {
                await reminderScheduler.scheduleReminders(for: plannerItems)
            } else {
                await reminderScheduler.clearScheduledReminders()
            }
            
            await syncAssignments(for: courses, dataManager: dataManager)
        } catch {
            lastError = error.localizedDescription
        }
        
        isSyncing = false
    }
    
    func syncAssignments(for course: CanvasCourse, dataManager: DataManager) async {
        do {
            let assignments = try await apiClient.fetchAssignments(for: course.id)
            dataManager.setCanvasAssignments(assignments, for: course.id)
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    private func syncAssignments(for courses: [CanvasCourse], dataManager: DataManager) async {
        await withTaskGroup(of: Void.self) { group in
            for course in courses {
                group.addTask { [weak self] in
                    guard let self else { return }
                    await self.syncAssignments(for: course, dataManager: dataManager)
                }
            }
        }
    }
}

