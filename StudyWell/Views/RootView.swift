import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: TaskStore

    @State private var selectedTab: AppTab = .today
    @State private var editorRoute: TaskEditorRoute?

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                TodayView(
                    onAdd: {
                        openNewTask()
                    },
                    onEdit: { task in
                        openEditor(for: task)
                    },
                    onOpenGoals: {
                        selectedTab = .goals
                    }
                )
            }
            .tabItem {
                Label("Today", systemImage: "sun.max")
            }
            .tag(AppTab.today)

            NavigationStack {
                TasksView(
                    onAdd: {
                        openNewTask()
                    },
                    onEdit: { task in
                        openEditor(for: task)
                    }
                )
            }
            .tabItem {
                Label("Tasks", systemImage: "checklist")
            }
            .tag(AppTab.tasks)

            NavigationStack {
                GoalsView()
            }
            .tabItem {
                Label("Goals", systemImage: "target")
            }
            .tag(AppTab.goals)
        }
        .sheet(item: $editorRoute) { route in
            NavigationStack {
                TaskEditorView(task: route.task)
            }
        }
        .alert(
            "Could not update task",
            isPresented: Binding(
                get: {
                    store.actionError != nil &&
                        editorRoute == nil
                },
                set: { isPresented in
                    if !isPresented {
                        store.actionError = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                store.actionError = nil
            }
        } message: {
            Text(
                store.actionError ??
                    "Please try again."
            )
        }
    }

    private func openNewTask() {
        store.actionError = nil
        editorRoute = TaskEditorRoute(task: nil)
    }

    private func openEditor(for task: StudyTask) {
        store.actionError = nil
        editorRoute = TaskEditorRoute(task: task)
    }
}

private enum AppTab: Hashable {
    case today
    case tasks
    case goals
}

// Each presentation has its own identity.
// A nil task opens the form in creation mode.
private struct TaskEditorRoute: Identifiable {
    let id = UUID()
    let task: StudyTask?
}