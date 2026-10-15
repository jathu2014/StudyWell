import Foundation
import CoreData

// Keep database operations on the main thread.
@MainActor
final class TaskRepository {
    private let persistence: PersistenceController

    init(inMemory: Bool = false) throws {
        persistence = try PersistenceController(
            inMemory: inMemory
        )
    }

    // Load all saved tasks, ordered by deadline.
    func fetch() throws -> [StudyTask] {
        let request = NSFetchRequest<NSManagedObject>(
            entityName: "TaskRecord"
        )

        request.sortDescriptors = [
            NSSortDescriptor(
                key: "dueDate",
                ascending: true
            )
        ]

        let records = try persistence.context.fetch(request)

        return try records.map { record in
            guard
                let id = record.value(forKey: "id") as? UUID,
                let title = record.value(forKey: "title") as? String,
                let dueDate = record.value(forKey: "dueDate") as? Date,
                let createdAt = record.value(forKey: "createdAt") as? Date
            else {
                throw RepositoryError.invalidRecord
            }

            let categoryValue =
                record.value(forKey: "category") as? String ?? ""

            let priorityValue =
                (record.value(forKey: "priority") as? NSNumber)?
                    .intValue ?? 1

            return StudyTask(
                id: id,
                title: title,
                module: record.value(forKey: "module") as? String ?? "",
                category: TaskCategory(rawValue: categoryValue)
                    ?? .coursework,
                priority: TaskPriority(rawValue: priorityValue)
                    ?? .normal,
                dueDate: dueDate,
                notes: record.value(forKey: "notes") as? String ?? "",
                reminderDate:
                    record.value(forKey: "reminderDate") as? Date,
                createdAt: createdAt,
                completedAt:
                    record.value(forKey: "completedAt") as? Date
            )
        }
    }

    // Insert a new task or update the task with the same ID.
    func save(_ task: StudyTask) throws {
        let context = persistence.context

        do {
            let existingRecord = try find(task.id)

            let record = existingRecord ??
                NSEntityDescription.insertNewObject(
                    forEntityName: "TaskRecord",
                    into: context
                )

            record.setValue(task.id, forKey: "id")
            record.setValue(task.title, forKey: "title")
            record.setValue(task.module, forKey: "module")
            record.setValue(
                task.category.rawValue,
                forKey: "category"
            )
            record.setValue(
                task.priority.rawValue,
                forKey: "priority"
            )
            record.setValue(task.dueDate, forKey: "dueDate")
            record.setValue(task.notes, forKey: "notes")
            record.setValue(
                task.reminderDate,
                forKey: "reminderDate"
            )
            record.setValue(task.createdAt, forKey: "createdAt")
            record.setValue(
                task.completedAt,
                forKey: "completedAt"
            )

            try context.save()
        } catch {
            // Discard unsaved changes if saving fails.
            context.rollback()
            throw error
        }
    }

    // Delete a task using its unique ID.
    func delete(_ id: UUID) throws {
        let context = persistence.context

        do {
            if let record = try find(id) {
                context.delete(record)
                try context.save()
            }
        } catch {
            context.rollback()
            throw error
        }
    }

    private func find(_ id: UUID) throws -> NSManagedObject? {
        let request = NSFetchRequest<NSManagedObject>(
            entityName: "TaskRecord"
        )

        request.predicate = NSPredicate(
            format: "id == %@",
            id as NSUUID
        )

        request.fetchLimit = 1

        return try persistence.context.fetch(request).first
    }

    private enum RepositoryError: LocalizedError {
        case invalidRecord

        var errorDescription: String? {
            switch self {
            case .invalidRecord:
                return """
                A saved task could not be read. \
                Your stored data has not been deleted.
                """
            }
        }
    }
}