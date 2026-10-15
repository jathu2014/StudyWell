import SwiftUI

struct GoalsView: View {
    @EnvironmentObject private var store: TaskStore
    @EnvironmentObject private var health: HealthService

    // These keys match the Today dashboard.
    // Changes are saved automatically on this device.
    @AppStorage("weeklyTaskGoal")
    private var weeklyTaskGoal = 5

    @AppStorage("dailyStepGoal")
    private var dailyStepGoal = 6000

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    introduction

                    studyGoalCard(date: timeline.date)

                    movementGoalCard

                    healthConnectionCard
                }
                .padding()
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
            }
            .background(Brand.background)
            .refreshable {
                await health.refreshIfRequested()
            }
        }
        .navigationTitle("Goals & Wellness")
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Small goals. Steady progress.")
                .font(.title2.weight(.semibold))

            Text("Choose targets that fit your own routine.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func studyGoalCard(date: Date) -> some View {
        let completed = TaskRules.weeklyCompleted(
            store.tasks,
            now: date
        )

        return VStack(alignment: .leading, spacing: 16) {
            Label(
                "Weekly task goal",
                systemImage: "checklist"
            )
            .font(.headline)

            if let storageError = store.storageError {
                Text(storageError)
                    .font(.subheadline)
                    .foregroundStyle(.red)
            } else {
                ProgressRing(
                    current: completed,
                    goal: weeklyTaskGoal,
                    label: "Weekly task goal"
                )

                Text("\(completed) of \(weeklyTaskGoal) tasks completed")
                    .font(.subheadline.weight(.medium))

                Stepper(
                    value: $weeklyTaskGoal,
                    in: 1...50
                ) {
                    Text("Target: \(weeklyTaskGoal) tasks")
                }

                Text(
                    """
                    Counts tasks completed during the current calendar \
                    week. Reopening or deleting a completed task removes \
                    it from this total.
                    """
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
        .studyCard()
    }

    private var movementGoalCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(
                "Daily movement goal",
                systemImage: "figure.walk"
            )
            .font(.headline)

            if let steps = health.steps {
                ProgressRing(
                    current: steps,
                    goal: dailyStepGoal,
                    label: "Daily step goal"
                )

                Text(
                    "\(steps.formatted()) of \(dailyStepGoal.formatted()) steps"
                )
                .font(.subheadline.weight(.medium))
            } else {
                Label(
                    "Step data unavailable",
                    systemImage: "heart.text.clipboard"
                )
                .foregroundStyle(.secondary)
            }

            Stepper(
                value: $dailyStepGoal,
                in: 500...30000,
                step: 500
            ) {
                Text("Target: \(dailyStepGoal.formatted()) steps")
            }

            Text(
                """
                This is your personal target. Step totals reflect \
                records available in Apple Health for today.
                """
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .studyCard()
    }

    private var healthConnectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(
                "Apple Health",
                systemImage: "heart.fill"
            )
            .font(.headline)

            Text(health.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if health.isLoading {
                ProgressView("Checking Apple Health…")
            }

            if health.hasRequestedAccess {
                Button {
                    Task {
                        await health.refreshIfRequested()
                    }
                } label: {
                    Label(
                        "Refresh steps",
                        systemImage: "arrow.clockwise"
                    )
                }
                .buttonStyle(.borderedProminent)
                .disabled(health.isLoading || !health.isAvailable)

                Text(
                    """
                    To review permissions, open the Health app, \
                    tap your profile, and find StudyWell under \
                    Apps or Apps and Services.
                    """
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            } else {
                Button {
                    Task {
                        await health.connect()
                    }
                } label: {
                    Label(
                        "Connect Apple Health",
                        systemImage: "heart"
                    )
                }
                .buttonStyle(.borderedProminent)
                .disabled(health.isLoading || !health.isAvailable)
            }

            if !health.isAvailable {
                Text(
                    """
                    Apple Health is unavailable in this environment. \
                    You can still manage tasks and study goals.
                    """
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            if let updated = health.lastUpdated {
                Text(
                    "Last updated: \(updated.formatted(date: .abbreviated, time: .shortened))"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Divider()

            Text(
                """
                StudyWell only requests permission to read steps. \
                It does not write health records or upload your health \
                data. You can use task management without connecting Health.
                """
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .studyCard()
    }
}