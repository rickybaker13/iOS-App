import Foundation
import UserNotifications

actor CanvasReminderScheduler {
    private let notificationCenter = UNUserNotificationCenter.current()
    private let reminderOffsets: [TimeInterval] = [24 * 60 * 60, 60 * 60] // 24h and 1h
    
    func scheduleReminders(for items: [CanvasPlannerItem]) async {
        let granted = try? await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
        guard granted == true else { return }
        
        await clearScheduledReminders()
        
        for item in items {
            guard let dueDate = item.dueAt else { continue }
            for offset in reminderOffsets {
                let fireDate = dueDate.addingTimeInterval(-offset)
                if fireDate <= Date() { continue }
                
                let content = UNMutableNotificationContent()
                content.title = "\(item.type.displayName) due: \(item.title)"
                if let courseName = item.courseName {
                    content.body = "\(courseName) • Due \(formatted(date: dueDate))"
                } else {
                    content.body = "Due \(formatted(date: dueDate))"
                }
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: fireDate.timeIntervalSinceNow, repeats: false)
                let identifier = "canvas-\(item.id)-\(Int(offset))"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                try? await notificationCenter.add(request)
            }
        }
    }
    
    func clearScheduledReminders() async {
        await notificationCenter.removeAllPendingNotificationRequests()
    }
    
    private func formatted(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

