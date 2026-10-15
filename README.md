# StudyWell

StudyWell is a student study and wellness planner built with SwiftUI.

It helps students manage tasks, deadlines, reminders, weekly task goals,
and a personal daily movement goal.

## Features

- Create and edit academic or personal tasks.
- Set a module, category, priority, deadline, and notes.
- Search tasks and filter by completion status.
- Complete, reopen, and delete tasks.
- Schedule local deadline reminders.
- Set a weekly task-completion target.
- Read today's recorded steps through Apple HealthKit.
- Set a personal daily step target.
- Support Light Mode, Dark Mode, and larger text sizes.

## Screens

1. Today dashboard
2. Tasks
3. Add/Edit Task
4. Goals & Wellness

## Technologies

- Swift and SwiftUI for the application and interface.
- Core Data for task persistence.
- UserDefaults through AppStorage for goal preferences.
- UserNotifications for local reminders.
- HealthKit for reading daily step totals.
- XCTest for automated unit tests.

## Advanced framework integration

StudyWell integrates HealthKit, which is explicitly accepted in the
assignment brief.

With permission, the app reads daily step totals and compares them with
the user's movement goal. This connects physical activity awareness with
study planning.

HealthKit reads recorded health data; StudyWell does not itself count steps.

## Privacy and permissions

- The app requests read access to step counts only.
- It does not write health records.
- It does not upload health data.
- Task management works without HealthKit access.
- HealthKit does not disclose whether read permission was denied.
  Missing data is therefore shown as unavailable, not as proof of denial.
- Notifications require permission. Sound and vibration depend on the
  device's settings and Focus configuration.
- Task titles appear in reminder notifications, subject to the user's
  notification-preview settings.

## Project structure

StudyWell/
├── StudyWell/
│   ├── App/
│   ├── Components/
│   ├── Models/
│   ├── Persistence/
│   ├── Resources/
│   ├── Services/
│   ├── ViewModels/
│   ├── Views/
│   └── StudyWell.entitlements
├── StudyWellTests/
├── docs/
├── .gitignore
└── README.md

## Development requirements

- Source files can be edited on Windows.
- Building and running the iOS application requires a Mac with Xcode.
- Use Xcode 16 or later with an appropriate installed iOS Simulator.
- Set the app deployment target to iOS 17.0 or later.
- Validate HealthKit permissions and real step data on an iPhone.
- Physical-device signing requires a development team and provisioning
  configuration that support the HealthKit capability.

## Initial Xcode project setup

These source files do not yet include an Xcode project.

Perform these steps once on the Mac:

1. Clone this repository.

2. In a separate temporary folder outside the repository, create a new
   Xcode iOS App project named StudyWell:
   - Interface: SwiftUI
   - Language: Swift
   - Storage: None
   - Include an XCTest unit-test target if the template offers it.

3. Close the temporary project.

4. Copy its StudyWell.xcodeproj into the repository's outer StudyWell
   folder, beside README.md.

5. Copy the generated Assets.xcassets into the repository's inner
   StudyWell folder. Keep the source files already in the repository.

6. Open the copied StudyWell.xcodeproj from the repository.

7. Check the Project Navigator:
   - Ensure all application Swift files are included in the StudyWell
     application target.
   - If files are missing, use Add Files to StudyWell to add them from
     the repository.
   - Remove references to template files that are absent, such as
     ContentView.swift.
   - Keep exactly one @main entry point: our StudyWellApp.swift.
   - Do not include test files in the application target.

8. Set the application target's build settings:
   - iOS Deployment Target: 17.0 or later
   - Swift Language Version: Swift 5
   - Default Actor Isolation: nonisolated, if this setting is available
   - Generate Info.plist File: No
   - Info.plist File: StudyWell/Resources/Info.plist
   - Code Signing Entitlements: StudyWell/StudyWell.entitlements
   - Marketing Version: 1.0
   - Current Project Version: 1

9. Under Signing & Capabilities:
   - Choose your development team.
   - Choose a unique bundle identifier.
   - Enable automatic signing.
   - Add the HealthKit capability.
   - Background Delivery and Clinical Health Records are not needed.

10. Check Build Phases > Copy Bundle Resources:
    - Info.plist must not be copied as a resource.
    - The entitlements file must not be copied as a resource.
    - With synchronized folders, remove their resource target membership
      or add the appropriate membership exception if necessary.

11. Configure the unit-test target:
    - If no test target exists, add an iOS Unit Testing Bundle.
    - Name it StudyWellTests and select StudyWell as its host application.
    - Include TaskRulesTests.swift in this test target only.
    - Remove references to missing template test files.
    - Ensure the application module is named StudyWell.

12. Select an installed iPhone Simulator and build with Command + B.

13. Run with Command + R and record any build errors or runtime problems.

14. Commit and push the working Xcode project, asset catalogue, and any
    necessary fixes so the Windows checkout can pull them.

The Xcode project should only need creating once.

## Running unit tests

After configuring the test target, use Product > Test or Command + U.

The supplied TaskRulesTests cover:
- Blank titles.
- Valid task input.
- Invalid reminder times.
- Completed-task reminder suppression.
- Search and filtering.
- Deadline ordering.
- Calendar-week completion counting.

Test results must be recorded after running them.
The existence of test files does not mean the tests have passed.

## Manual verification

Before submission, check:

- Create, edit, complete, reopen, and delete tasks.
- Close and reopen the app to verify saved tasks and goals.
- Search and filter tasks.
- Confirm deletion requires confirmation.
- Schedule a reminder a few minutes ahead.
- Test reminders with the app open and in the background.
- Complete or delete a task before its reminder and verify cancellation.
- Try notification permission denial.
- Request HealthKit access and compare available steps with Apple Health.
- Test missing health data and disabled Health access.
- Change goal targets and check both screens update.
- Try Dark Mode, larger text, and landscape orientation.

## Known scope and limitations

- No accounts, server, or cloud synchronization.
- Goals are simple numeric targets.
- The weekly completion total counts tasks still present in the app.
  Deleting or reopening a completed task reduces that total.
- Step data refreshes when the app becomes active or the user refreshes.
- The app does not continuously monitor activity in the background.
- Only the next 50 eligible reminders are scheduled.
  Opening the app refreshes the reminder queue.
- Opening a notification launches the app but does not navigate directly
  to its task.
- A custom app icon, UI tests, user acceptance testing, and the final
  assignment report remain to be completed.

## Verification status

The source has been prepared manually on Windows.

Compilation, automated test results, real-device HealthKit behaviour,
and final visual checks are not yet verified.

Update this section with actual results after testing on the Mac.

## Assignment documentation

Keep documentation in docs/, including:
- User guide.
- Architecture and implementation explanation.
- Design decisions and development challenges.
- Actual testing results.
- Reflections.
- References and assistance acknowledgements.
- AI-use record containing prompts, responses, and how they were used.

This is an individual assignment. Document build/test assistance and
understand the submitted implementation.

## References

- SwiftUI:
  https://developer.apple.com/documentation/swiftui
- Core Data:
  https://developer.apple.com/documentation/coredata
- HealthKit:
  https://developer.apple.com/documentation/healthkit
- HealthKit authorization:
  https://developer.apple.com/documentation/healthkit/authorizing-access-to-health-data
- UserNotifications:
  https://developer.apple.com/documentation/usernotifications