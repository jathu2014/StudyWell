import SwiftUI

struct TaskRow: View {
    let task: StudyTask
    let onToggleCompletion: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // A separate button for completing or reopening the task.
            Button(action: onToggleCompletion) {
                Image(
                    systemName: task.isCompleted
                        ? "checkmark.circle.fill"
                        : "circle"
                )
                .font(.title2)
                .foregroundStyle(
                    task.isCompleted
                        ? Brand.accent
                        : Color.secondary
                )
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                task.isCompleted
                    ? "Mark \(task.title) incomplete"
                    : "Mark \(task.title) complete"
            )

            // Tapping the task information opens its editor.
            Button(action: onEdit) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(task.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .strikethrough(task.isCompleted)
                        .multilineTextAlignment(.leading)

                    Text(categoryDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)

                    Label {
                        Text(
                            task.dueDate.formatted(
                                date: .abbreviated,
                                time: .shortened
                            )
                        )
                    } icon: {
                        Image(systemName: "calendar")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    // Text labels ensure status is not conveyed
                    // through colour alone.
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 12) {
                            priorityLabel
                            statusLabel
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            priorityLabel
                            statusLabel
                        }
                    }
                    .font(.caption.weight(.medium))
                }
                .frame(
                    maxWidth: .infinity,
                    minHeight: 44,
                    alignment: .leading
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Opens the task editor")
        }
        .padding(.vertical, 6)
    }

    private var categoryDescription: String {
        if task.module.isEmpty {
            return task.category.rawValue
        }

        return "\(task.category.rawValue) · \(task.module)"
    }

    private var priorityLabel: some View {
        Label(
            "\(task.priority.label) priority",
            systemImage: task.priority == .high
                ? "flag.fill"
                : "flag"
        )
        .foregroundStyle(
            task.priority == .high
                ? Brand.accent
                : Color.secondary
        )
    }

    @ViewBuilder
    private var statusLabel: some View {
        if task.isCompleted {
            Label("Completed", systemImage: "checkmark")
                .foregroundStyle(Brand.accent)
        } else if task.isOverdue() {
            Label(
                "Overdue",
                systemImage: "exclamationmark.circle"
            )
            .foregroundStyle(.red)
        } else if task.reminderDate != nil {
            Label("Reminder set", systemImage: "bell")
                .foregroundStyle(.secondary)
        }
    }
}