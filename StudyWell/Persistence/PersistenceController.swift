import Foundation
import CoreData

final class PersistenceController {
    let container: NSPersistentContainer

    var context: NSManagedObjectContext {
        container.viewContext
    }

    // In-memory storage is available for automated tests.
    init(inMemory: Bool = false) throws {
        container = NSPersistentContainer(
            name: "StudyWell",
            managedObjectModel: Self.makeModel()
        )

        let description = NSPersistentStoreDescription()

        if inMemory {
            description.type = NSInMemoryStoreType
        } else {
            let directory =
                NSPersistentContainer.defaultDirectoryURL()

            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
                attributes: nil
            )

            description.url = directory
                .appendingPathComponent("StudyWell.sqlite")
        }

        // Finish loading before the app tries to read tasks.
        description.shouldAddStoreAsynchronously = false
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true

        container.persistentStoreDescriptions = [description]

        var loadingError: Error?

        container.loadPersistentStores { _, error in
            loadingError = error
        }

        if let loadingError = loadingError {
            throw loadingError
        }

        context.mergePolicy =
            NSMergeByPropertyObjectTrumpMergePolicy

        context.automaticallyMergesChangesFromParent = true
    }

    // Define the database schema in Swift.
    // This avoids needing Xcode's visual model editor on Windows.
    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let entity = NSEntityDescription()
        entity.name = "TaskRecord"
        entity.managedObjectClassName = "NSManagedObject"

        entity.properties = [
            attribute("id", type: .UUIDAttributeType),
            attribute("title", type: .stringAttributeType),
            attribute("module", type: .stringAttributeType),
            attribute("category", type: .stringAttributeType),
            attribute("priority", type: .integer16AttributeType),
            attribute("dueDate", type: .dateAttributeType),
            attribute("notes", type: .stringAttributeType),
            attribute(
                "reminderDate",
                type: .dateAttributeType,
                optional: true
            ),
            attribute("createdAt", type: .dateAttributeType),
            attribute(
                "completedAt",
                type: .dateAttributeType,
                optional: true
            )
        ]

        // Prevent two records from having the same task ID.
        entity.uniquenessConstraints = [["id"]]

        model.entities = [entity]

        return model
    }

    private static func attribute(
        _ name: String,
        type: NSAttributeType,
        optional: Bool = false
    ) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = optional
        return attribute
    }
}