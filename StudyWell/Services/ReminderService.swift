import Foundation
import UserNotifications

// An actor protects reminder scheduling when several tasks change.
actor ReminderService {
    private let center = UNUserNotificationCenter.current()
    private let disabled: Bool
    private let prefix = "studywell.task."

    private var isUpdating = false
    private var queuedTasks: [StudyTask]?

    // Automated tests can disable real notifications.
    init(disabled: Bool = false) {
        self.disabled = disabled
    }

    // Call this when the user chooses to enable a reminder.
    func requestPermission() async throws -> Bool {
        guard !disabled else {
            return true
        }

        return try await center.requestAuthorization(
            options: [.alert, .sound]
        )
    }

    // Update scheduled reminders to match the saved tasks.
    // Returns a message if something needs the user's attention.
    func reconcile(_ tasks: [StudyTask]) async -> String? {
        guard !disabled else {
            return nil
        }

        queuedTasks = tasks

        guard !isUpdating else {
            return nil
        }

        isUpdating = true

        defer {
            isUpdating = false
        }

        var message: String?

        // If tasks change while scheduling, process the latest list.
        while let latestTasks = queuedTasks {
            queuedTasks = nil
            message = await replaceRequests(for: latestTasks)
        }

        return message
    }

    private func replaceRequests(
        for tasks: [StudyTask]
    ) async -> String? {
        // Remove old StudyWell reminders so edits, deletions,
        // and completed tasks do not leave outdated notifications.
        let pending = await center.pendingNotificationRequests()

        let oldIdentifiers = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(prefix) }

        center.removePendingNotificationRequests(
            withIdentifiers: oldIdentifiers
        )

        let now = Date()

        let eligibleTasks = tasks
            .filter { $0.futureReminder(at: now) != nil }
            .sorted {
                ($0.reminderDate ?? .distantFuture) <
                    ($1.reminderDate ?? .distantFuture)
            }

        guard !eligibleTasks.isEmpty else {
            return nil
        }

        let settings = await center.notificationSettings()

        let canNotify =
            settings.authorizationStatus == .authorized ||
            settings.authorizationStatus == .provisional

        guard canNotify else {
            return """
            Your tasks are saved, but notifications are not enabled. \
            You can enable them in iPhone Settings.
            """
        }

        var failedCount = 0

        // Keep a bounded queue. Later reminders are added when
        // the app opens again and refreshes its schedule.
        for task in eligibleTasks.prefix(50) {
            guard let reminderDate = task.futureReminder() else {
                continue
            }

            let content = UNMutableNotificationContent()
            content.title = "StudyWell reminder"

            let deadline = task.dueDate.formatted(
                date: .abbreviated,
                time: .shortened
            )

            content.body = "\(task.title) — Due \(deadline)"
            content.sound = .default
            content.userInfo = [
                "taskID": task.id.uuidString
            ]

            var components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: reminderDate
            )

            components.calendar = Calendar.current
            components.timeZone = TimeZone.current

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: components,
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: prefix + task.id.uuidString,
                content: content,
                trigger: trigger
            )

            do {
                try await center.add(request)
            } catch {
                failedCount += 1
            }
        }

        if failedCount > 0 {
            return """
            Your tasks are saved, but \(failedCount) reminder(s) \
            could not be scheduled. Open the app again to retry.
            """
        }

        if eligibleTasks.count > 50 {
            return """
            The next 50 reminders are scheduled. \
            Open StudyWell regularly to schedule later reminders.
            """
        }

        return nil
    }
}