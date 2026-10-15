import SwiftUI

@main
@MainActor
struct StudyWellApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate

    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var taskStore: TaskStore
    @StateObject private var healthService: HealthService

    init() {
        // Automated UI tests use temporary task storage
        // and do not request notification or Health permissions.
        let isUITesting = ProcessInfo.processInfo.arguments
            .contains("--ui-testing")

        let reminders = ReminderService(
            disabled: isUITesting
        )

        _taskStore = StateObject(
            wrappedValue: TaskStore(
                inMemory: isUITesting,
                reminders: reminders
            )
        )

        _healthService = StateObject(
            wrappedValue: HealthService(
                disabled: isUITesting
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(taskStore)
                .environmentObject(healthService)
                .tint(Brand.accent)
                .task {
                    // Restore reminder scheduling and refresh
                    // health data when the interface first opens.
                    await taskStore.refreshReminders()
                    await healthService.refreshIfRequested()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else {
                        return
                    }

                    // Refresh after returning from Settings,
                    // Apple Health, or another app.
                    Task {
                        await taskStore.refreshReminders()
                        await healthService.refreshIfRequested()
                    }
                }
        }
    }
}