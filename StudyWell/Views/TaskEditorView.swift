import SwiftUI

struct TaskEditorView: View {
    @EnvironmentObject private var store: TaskStore
    @Environment(\.dismiss) private var dismiss

    @State private var draft: StudyTask
    @State private var reminderEnabled: Bool
    @State private var reminderDate: Date
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let originalTask: StudyTask?

    // Passing a task opens editing mode.
    // Passing nothing opens a blank task form.
    init(task: StudyTask? = nil) {
        originalTask = task

        let initialTask = task ?? StudyTask(
            title: "",
            dueDate: Date().addingTimeInterval(24 * 60 * 60)
        )

        _draft = State(initialValue: initialTask)

        _reminderEnabled = State(
            initialValue: initialTask.reminderDate != nil
        )

        _reminderDate = State(
            initialValue: initialTask.reminderDate ??
                initialTask.dueDate.addingTimeInterval(-60 * 60)
        )
    }

    var body: some View {
        Form {
            Section("Task details") {
                TextField("Task title", text: $draft.title)
                    .textInputAutocapitalization(.sentences)
                    .accessibilityIdentifier("taskTitleField")

                TextField(
                    "Module or subject (optional)",
                    text: $draft.module
                )
                .textInputAutocapitalization(.words)

                Picker("Category", selection: $draft.category) {
                    ForEach(TaskCategory.allCases) { category in
                        Text(category.rawValue)
                            .tag(category)
                    }
                }

                Picker("Priority", selection: $draft.priority) {
                    ForEach(TaskPriority.allCases) { priority in
                        Text(priority.label)
                            .tag(priority)
                    }
                }
            }

            Section("Deadline") {
                DatePicker(
                    "Due",
                    selection: $draft.dueDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
            }

            Section {
                Toggle(
                    "Remind me",
                    isOn: $reminderEnabled
                )

                if reminderEnabled {
                    DatePicker(
                        "Reminder time",
                        selection: $reminderDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
            } header: {
                Text("Reminder")
            } footer: {
                Text(
                    draft.isCompleted
                        ? "Completed tasks do not send reminders."
                        : """
                        Choose a time at or before the deadline. \
                        Notifications depend on your iPhone settings.
                        """
                )
            }

            Section("Notes") {
                TextField(
                    "Add instructions or a short note",
                    text: $draft.notes,
                    axis: .vertical
                )
                .lineLimit(3...6)
            }
        }
        .disabled(isSaving)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(
            originalTask == nil ? "New task" : "Edit task"
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
                .disabled(isSaving)
            }

            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task {
                        await saveTask()
                    }
                } label: {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Save")
                            .fontWeight(.semibold)
                    }
                }
                .disabled(
                    isSaving ||
                    draft.title.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty
                )
                .accessibilityLabel("Save task")
                .accessibilityIdentifier("saveTaskButton")
            }
        }
        .interactiveDismissDisabled(isSaving)
        .alert(
            "Could not save task",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        errorMessage = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
    }

    @MainActor
    private func saveTask() async {
        guard !isSaving else {
            return
        }

        isSaving = true

        defer {
            isSaving = false
        }

        var taskToSave = draft
        taskToSave.reminderDate =
            reminderEnabled ? reminderDate : nil

        // An old reminder may already have fired.
        // Only revalidate its timing when relevant fields change.
        let reminderChanged =
            originalTask == nil ||
            taskToSave.reminderDate != originalTask?.reminderDate ||
            taskToSave.dueDate != originalTask?.dueDate

        let saved = await store.save(
            taskToSave,
            reminderChanged: reminderChanged
        )

        if saved {
            dismiss()
        } else {
            errorMessage =
                store.actionError ?? "Please try again."

            // This screen presents the error itself.
            store.actionError = nil
        }
    }
}