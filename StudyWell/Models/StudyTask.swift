import Foundation

// The kind of task the student wants to complete.
enum TaskCategory: String, CaseIterable, Identifiable {
    case coursework = "Coursework"
    case revision = "Revision"
    case personal = "Personal"

    var id: String { rawValue }
}

// Priority values can be stored in Core Data.
enum TaskPriority: Int, CaseIterable, Identifiable {
    case low = 0
    case normal = 1
    case high = 2

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .low:
            return "Low"
        case .normal:
            return "Normal"
        case .high:
            return "High"
        }
    }
}

// Represents one task in the app.
struct StudyTask: Identifiable, Equatable {
    var id = UUID()
    var title: String
    var module: String = ""
    var category: TaskCategory = .coursework
    var priority: TaskPriority = .normal
    var dueDate: Date
    var notes: String = ""
    var reminderDate: Date?
    var createdAt = Date()
    var completedAt: Date?

    var isCompleted: Bool {
        completedAt != nil
    }

    func isOverdue(at now: Date = Date()) -> Bool {
        !isCompleted && dueDate < now
    }

    // Only unfinished tasks with a future reminder can notify.
    func futureReminder(at now: Date = Date()) -> Date? {
        guard !isCompleted,
              let date = reminderDate,
              date > now else {
            return nil
        }

        return date
    }
}