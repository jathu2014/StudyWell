import Foundation

enum TaskFilter: String, CaseIterable, Identifiable {
    case pending = "Pending"
    case completed = "Completed"
    case all = "All"

    var id: String { rawValue }
}

enum TaskRules {

    // Filter by completion status and search text.
    // Show unfinished tasks first, then earliest deadlines.
    static func filtered(
        _ tasks: [StudyTask],
        filter: TaskFilter,
        search: String
    ) -> [StudyTask] {
        let query = search.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return tasks.filter { task in
            let matchesStatus: Bool

            switch filter {
            case .pending:
                matchesStatus = !task.isCompleted
            case .completed:
                matchesStatus = task.isCompleted
            case .all:
                matchesStatus = true
            }

            let searchableText = [
                task.title,
                task.module,
                task.category.rawValue
            ]

            let matchesSearch = query.isEmpty ||
                searchableText.contains {
                    $0.localizedCaseInsensitiveContains(query)
                }

            return matchesStatus && matchesSearch
        }
        .sorted { first, second in
            if first.isCompleted != second.isCompleted {
                return !first.isCompleted
            }

            if first.dueDate != second.dueDate {
                return first.dueDate < second.dueDate
            }

            return first.priority.rawValue >
                second.priority.rawValue
        }
    }

    // Count completions within the current calendar week.
    static func weeklyCompleted(
        _ tasks: [StudyTask],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        guard let week = calendar.dateInterval(
            of: .weekOfYear,
            for: now
        ) else {
            return 0
        }

        return tasks.filter { task in
            guard let completedAt = task.completedAt else {
                return false
            }

            return completedAt >= week.start &&
                completedAt < week.end
        }.count
    }

    // Return an explanation when input is invalid.
    // Return nil when the task is valid.
    static func validate(
        _ task: StudyTask,
        now: Date = Date(),
        validateReminder: Bool = true
    ) -> String? {
        let title = task.title.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if title.isEmpty {
            return "Give your task a title."
        }

        if title.count > 120 {
            return "Keep the title to 120 characters or fewer."
        }

        if validateReminder,
           !task.isCompleted,
           let reminder = task.reminderDate {

            if reminder <= now {
                return "Choose a future reminder time, or turn the reminder off."
            }

            if reminder > task.dueDate {
                return "Set the reminder at or before the deadline."
            }
        }

        return nil
    }
}