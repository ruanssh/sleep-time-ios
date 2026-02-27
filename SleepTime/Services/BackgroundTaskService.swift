import Foundation
import BackgroundTasks
import SwiftData

enum BackgroundTaskService {
    static let refreshIdentifier = "com.sleeptime.refresh"

    static func register() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: refreshIdentifier,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else { return }
            handleRefresh(refreshTask)
        }
    }

    static func scheduleRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: refreshIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60) // 30 min
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to schedule background refresh: \(error)")
        }
    }

    @MainActor
    private static func handleRefresh(_ task: BGAppRefreshTask) {
        scheduleRefresh()

        let container = try? ModelContainer(for: ActivityTimestamp.self, SleepRecord.self)
        guard let context = container?.mainContext else {
            task.setTaskCompleted(success: false)
            return
        }

        let timestamp = ActivityTimestamp(date: .now, source: .backgroundRefresh)
        context.insert(timestamp)
        try? context.save()

        task.setTaskCompleted(success: true)
    }
}
