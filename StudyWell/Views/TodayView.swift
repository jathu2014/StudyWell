import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: TaskStore
    @EnvironmentObject private var health: HealthService

    @AppStorage("weeklyTaskGoal")
    private var weeklyTaskGoal = 5

    @AppStorage("dailyStepGoal")
    private var dailyStepGoal = 6000

    let onAdd: () -> Void
    let onEdit: (StudyTask) -> Void
    let onOpenGoals: () -> Void

    private var upcomingTasks: [StudyTask] {
        Array(
            TaskRules.filtered(
                store.tasks,
                filter: .pending,
                search: ""
            )
            .prefix(5)
        )
    }

    var body: some View {
        // Refresh time-sensitive labels while the screen is open.
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    introduction(date: timeline.date)

                    if let storageError = store.storageError {
                        Label(
                            storageError,
                            systemImage: "exclamationmark.triangle"
                        )
                        .foregroundStyle(.red)
                        .studyCard()
                    } else {
                        studyProgress(date: timeline.date)
                    }

                    movementCard

                    if store.storageError == nil {
                        upcomingSection
                    }

                    if let message = store.reminderMessage {
                        Label(
                            message,
                            systemImage: "bell.badge"
                        )
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .studyCard()
                    }
                }
                .padding()
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
            }
            .background(Brand.background)
            .refreshable {
                await health.refreshIfRequested()
                await store.refreshReminders()
            }
        }
        .navigationTitle("Today")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onAdd) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add task")
                .disabled(store.storageError != nil)
            }
        }
    }

    private func introduction(date: Date) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(
                date.formatted(
                    .dateTime.weekday(.wide).month(.abbreviated).day()
                )
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Text("Make room for study and yourself.")
                .font(.title2.weight(.semibold))
        }
    }

    private func studyProgress(date: Date) -> some View {
        let completed = TaskRules.weeklyCompleted(
            store.tasks,
            now: date
        )

        return VStack(alignment: .leading, spacing: 16) {
            Label("This week's study goal", systemImage: "book")
                .font(.headline)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 24) {
                    ProgressRing(
                        current: completed,
                        goal: weeklyTaskGoal,
                        label: "Weekly task goal"
                    )

                    studySummary(completed: completed)
                }

                VStack(alignment: .leading, spacing: 16) {
                    ProgressRing(
                        current: completed,
                        goal: weeklyTaskGoal,
                        label: "Weekly task goal"
                    )

                    studySummary(completed: completed)
                }
            }

            Button("Manage goals", action: onOpenGoals)
                .font(.subheadline.weight(.semibold))
        }
        .studyCard()
    }

    private func studySummary(completed: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(completed) of \(weeklyTaskGoal) tasks")
                .font(.title3.weight(.semibold))

            Text(
                completed >= weeklyTaskGoal
                    ? "You've reached your weekly target."
                    : "Every completed task is a step forward."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var movementCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Today's movement", systemImage: "figure.walk")
                .font(.headline)

            if let steps = health.steps {
                Text("\(steps.formatted()) steps")
                    .font(.title2.weight(.semibold))
                    .monospacedDigit()

                ProgressView(
                    value: min(Double(steps), Double(dailyStepGoal)),
                    total: Double(max(dailyStepGoal, 1))
                )
                .tint(Brand.accent)
                .accessibilityLabel("Daily movement goal")
                .accessibilityValue(
                    "\(steps) of \(dailyStepGoal) steps"
                )

                Text("Daily target: \(dailyStepGoal.formatted()) steps")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("Step data unavailable")
                    .font(.subheadline.weight(.medium))
            }

            Text(health.message)
                .font(.footnote)
                .foregroundStyle(.secondary)

            if health.isLoading {
                ProgressView("Updating steps…")
            }

            Button("Open goals & wellness", action: onOpenGoals)
                .font(.subheadline.weight(.semibold))
        }
        .studyCard()
    }

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Next up")
                .font(.title3.weight(.semibold))

            Text("Your earliest pending deadlines, including overdue tasks.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if upcomingTasks.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Label(
                        "You're all caught up",
                        systemImage: "checkmark.circle"
                    )
                    .font(.headline)

                    Text("Add a task when you're ready to plan your next step.")
                        .foregroundStyle(.secondary)

                    Button("Add a task", action: onAdd)
                        .buttonStyle(.borderedProminent)
                }
                .studyCard()
            } else {
                ForEach(upcomingTasks) { task in
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
                    .studyCard()
                }
            }
        }
    }
}