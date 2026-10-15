import SwiftUI

struct TasksView: View {
    @EnvironmentObject private var store: TaskStore

    @State private var searchText = ""
    @State private var selectedFilter: TaskFilter = .pending
    @State private var taskToDelete: StudyTask?

    let onAdd: () -> Void
    let onEdit: (StudyTask) -> Void

    private var filteredTasks: [StudyTask] {
        TaskRules.filtered(
            store.tasks,
            filter: selectedFilter,
            search: searchText
        )
    }

    var body: some View {
        List {
            Section {
                Picker("Show tasks", selection: $selectedFilter) {
                    ForEach(TaskFilter.allCases) { filter in
                        Text(filter.rawValue)
                            .tag(filter)
                    }
                }
                .pickerStyle(.menu)
            }

            if let storageError = store.storageError {
                Section {
                    Label(
                        storageError,
                        systemImage: "exclamationmark.triangle"
                    )
                    .foregroundStyle(.red)
                }
            } else if filteredTasks.isEmpty {
                Section {
                    ContentUnavailableView(
                        searchText.isEmpty
                            ? "No \(selectedFilter.rawValue.lowercased()) tasks"
                            : "No matching tasks",
                        systemImage: "checklist",
                        description: Text(
                            searchText.isEmpty
                                ? "Use the plus button to add a task, or choose another filter."
                                : "Try another title, module, or category."
                        )
                    )
                }
                .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(filteredTasks) { task in
                        TaskRow(
                            task: task,
                            onToggleCompletion: {
                                Task {
                                    await store.toggleCompletion(task)
                                }
                            },
                            onEdit: {
                                onEdit(task)
                            }
                        )
                        .swipeActions(
                            edge: .trailing,
                            allowsFullSwipe: false
                        ) {
                            Button(role: .destructive) {
                                taskToDelete = task
                            } label: {
                                Label(
                                    "Delete",
                                    systemImage: "trash"
                                )
                            }
                        }
                        .swipeActions(
                            edge: .leading,
                            allowsFullSwipe: false
                        ) {
                            Button {
                                Task {
                                    await store.toggleCompletion(task)
                                }
                            } label: {
                                Label(
                                    task.isCompleted
                                        ? "Reopen"
                                        : "Complete",
                                    systemImage: task.isCompleted
                                        ? "arrow.uturn.backward"
                                        : "checkmark"
                                )
                            }
                            .tint(Brand.accent)
                        }
                    }
                } header: {
                    Text("\(filteredTasks.count) tasks")
                }
            }

            if let message = store.reminderMessage {
                Section {
                    Label(
                        message,
                        systemImage: "bell.badge"
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Tasks")
        .searchable(
            text: $searchText,
            prompt: "Search title, module, or category"
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onAdd) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add task")
                .accessibilityIdentifier("addTaskButton")
                .disabled(store.storageError != nil)
            }
        }
        .confirmationDialog(
            "Delete this task?",
            isPresented: Binding(
                get: { taskToDelete != nil },
                set: { isPresented in
                    if !isPresented {
                        taskToDelete = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            if let task = taskToDelete {
                Button("Delete task", role: .destructive) {
                    Task {
                        await store.delete(task)
                    }

                    taskToDelete = nil
                }
            }

            Button("Cancel", role: .cancel) {
                taskToDelete = nil
            }
        } message: {
            Text(
                "This will delete the task and cancel its pending reminder."
            )
        }
    }
}