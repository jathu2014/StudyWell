import Foundation
import Combine

@MainActor
final class TaskStore: ObservableObject {
    @Published private(set) var tasks: [StudyTask] = []
    @Published private(set) var storageError: String? = nil
    @Published private(set) var reminderMessage: String? = nil

    @Published var actionError: String? = nil

    private var repository: TaskRepository?
    private let reminders: ReminderService

    init(
        inMemory: Bool = false,
        reminders: ReminderService
    ) {
        self.reminders = reminders

        do {
            let repository = try TaskRepository(
                inMemory: inMemory
            )

            tasks = try repository.fetch()
            self.repository = repository
        } catch {
            storageError = """
            Saved tasks could not be opened: \
            \(error.localizedDescription)
            """
        }
    }

    // Validate and save a new or edited task.
    func save(
        _ draft: StudyTask,
        reminderChanged: Bool = true
    ) async -> Bool {
        actionError = nil

        guard let repository = repository else {
            actionError = storageError ?? "Task storage is unavailable."
            return false
        }

        var task = draft

        task.title = task.title.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        task.module = task.module.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if let validationError = TaskRules.validate(
            task,
            validateReminder: reminderChanged
        ) {
            actionError = validationError
            return false
        }

        do {
            try repository.save(task)
        } catch {
            actionError = """
            Your task could not be saved: \
            \(error.localizedDescription)
            """
            return false
        }

        // Update the interface only after the database save succeeds.
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        } else {
            tasks.append(task)
        }

        sortTasks()

        var permissionMessage: String?

        if task.futureReminder() != nil {
            do {
                _ = try await reminders.requestPermission()
            } catch {
                permissionMessage = """
                Your task is saved, but notification permission \
                could not be requested. Check iPhone Settings.
                """
            }
        }

        await refreshReminders()

        if let permissionMessage = permissionMessage {
            reminderMessage = permissionMessage
        }

        return true
    }

    // Mark a task complete, or reopen a completed task.
    func toggleCompletion(_ task: StudyTask) async {
        actionError = nil

        guard let repository = repository else {
            actionError = storageError ?? "Task storage is unavailable."
            return
        }

        guard let index = tasks.firstIndex(
            where: { $0.id == task.id }
        ) else {
            return
        }

        var updated = tasks[index]

        updated.completedAt = updated.isCompleted ? nil : Date()

        do {
            try repository.save(updated)
            tasks[index] = updated
            sortTasks()

            // Completed tasks must no longer send reminders.
            await refreshReminders()
        } catch {
            actionError = """
            The completion change could not be saved: \
            \(error.localizedDescription)
            """
        }
    }

    func delete(_ task: StudyTask) async {
        actionError = nil

        guard let repository = repository else {
            actionError = storageError ?? "Task storage is unavailable."
            return
        }

        do {
            try repository.delete(task.id)

            tasks.removeAll { $0.id == task.id }

            // Also cancel any pending reminder for the deleted task.
            await refreshReminders()
        } catch {
            actionError = """
            The task could not be deleted: \
            \(error.localizedDescription)
            """
        }
    }

    // Also called when the app becomes active.
    func refreshReminders() async {
        guard repository != nil else {
            return
        }

        reminderMessage = await reminders.reconcile(tasks)
    }

    private func sortTasks() {
        tasks = TaskRules.filtered(
            tasks,
            filter: .all,
            search: ""
        )
    }
}