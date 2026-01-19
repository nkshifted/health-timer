# Reminders UI Polish Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement the Preferences window UI polish (fixed size, info popover, per-row Test button) and wire a safe test-notification path without changing scheduling behavior.

**Architecture:** Keep UI changes in `PreferencesWindow`, move instruction lookup/test callbacks into `RemindersViewModel`, and add a `NotificationManager.sendTestNotification(for:)` helper that only posts an immediate notification. Use a lightweight `UNUserNotificationCenter` protocol to test request construction.

**Tech Stack:** Swift, SwiftUI, AppKit (NSWindow), UserNotifications, XCTest.

---

### Task 1: Add tests for RemindersViewModel instructions + test action

**Files:**
- Create: `HealthTimer/HealthTimerTests/RemindersViewModelTests.swift`

**Step 1: Write failing tests**

```swift
import XCTest
@testable import HealthTimer

final class RemindersViewModelTests: XCTestCase {
    func testInstructionTextReturnsStoredInstructions() {
        let viewModel = RemindersViewModel(
            exerciseManager: ExerciseManager(),
            onScheduleChange: {},
            onTestNotification: { _ in }
        )

        let definition = ExerciseManager().getExerciseList().first!
        let text = viewModel.instructionText(for: definition.id)

        XCTAssertEqual(text, definition.instructions)
    }

    func testInstructionTextFallsBackForUnknownId() {
        let viewModel = RemindersViewModel(
            exerciseManager: ExerciseManager(),
            onScheduleChange: {},
            onTestNotification: { _ in }
        )

        let text = viewModel.instructionText(for: "missing-id")
        XCTAssertEqual(text, "Instructions unavailable.")
    }

    func testSendTestNotificationUsesCallbackDefinition() {
        let expectation = expectation(description: "test notification callback")
        var capturedId: String?

        let manager = ExerciseManager()
        let viewModel = RemindersViewModel(
            exerciseManager: manager,
            onScheduleChange: {},
            onTestNotification: { exercise in
                capturedId = exercise.id
                expectation.fulfill()
            }
        )

        let definition = manager.getExerciseList().first!
        viewModel.sendTestNotification(id: definition.id)

        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(capturedId, definition.id)
    }
}
```

**Step 2: Run tests (expect fail)**

Run: `xcodebuild test -scheme HealthTimer -destination 'platform=macOS'`
Expected: FAIL (missing `instructionText` / `sendTestNotification`).

**Step 3: Commit**

```bash
git add HealthTimer/HealthTimerTests/RemindersViewModelTests.swift
git commit -m "test: add reminders view model tests"
```

---

### Task 2: Add test for NotificationManager test-notification request

**Files:**
- Create: `HealthTimer/HealthTimerTests/NotificationManagerTests.swift`

**Step 1: Write failing tests**

```swift
import XCTest
import UserNotifications
@testable import HealthTimer

final class NotificationManagerTests: XCTestCase {
    private final class FakeNotificationCenter: UNUserNotificationCenterProtocol {
        var lastRequest: UNNotificationRequest?
        func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)?) {
            lastRequest = request
            completionHandler?(nil)
        }
        func removeAllPendingNotificationRequests() {}
    }

    func testSendTestNotificationBuildsImmediateRequest() {
        let fakeCenter = FakeNotificationCenter()
        let manager = NotificationManager(exerciseManager: ExerciseManager(), notificationCenter: fakeCenter)
        let exercise = ExerciseManager().getExerciseList().first!

        manager.sendTestNotification(for: exercise)

        let request = fakeCenter.lastRequest
        XCTAssertNotNil(request)
        XCTAssertTrue(request!.identifier.hasPrefix("EXERCISE_NOTIFICATION_TEST_"))
        XCTAssertEqual(request!.content.title, "Time for: \(exercise.name)")
        XCTAssertEqual(request!.content.body, exercise.instructions)
    }
}
```

**Step 2: Run tests (expect fail)**

Run: `xcodebuild test -scheme HealthTimer -destination 'platform=macOS'`
Expected: FAIL (protocol + method missing).

**Step 3: Commit**

```bash
git add HealthTimer/HealthTimerTests/NotificationManagerTests.swift
git commit -m "test: add notification manager test notification coverage"
```

---

### Task 3: Implement RemindersViewModel instruction map + test callback

**Files:**
- Modify: `HealthTimer/HealthTimer/RemindersViewModel.swift`

**Step 1: Implement minimal code to pass tests**

```swift
import OSLog

final class RemindersViewModel: ObservableObject {
    private let logger = Logger(subsystem: "com.healthtimer.app", category: "preferences")
    private let onTestNotification: (ExerciseDefinition) -> Void
    private var definitionsById: [String: ExerciseDefinition] = [:]

    func instructionText(for id: String) -> String { ... }
    func sendTestNotification(id: String) { ... }
}
```

- Build `definitionsById` in `load()` using the exercise list.
- `instructionText(for:)` returns stored text if present and non-empty.
- On missing/empty text, log a warning and return `"Instructions unavailable."`
- `sendTestNotification(id:)` looks up definition and invokes `onTestNotification` if found; logs warning if missing.

**Step 2: Run tests (expect pass)**

Run: `xcodebuild test -scheme HealthTimer -destination 'platform=macOS'`
Expected: PASS.

**Step 3: Commit**

```bash
git add HealthTimer/HealthTimer/RemindersViewModel.swift
git commit -m "feat: add reminders view model instruction + test actions"
```

---

### Task 4: Implement NotificationManager test notification helper

**Files:**
- Modify: `HealthTimer/HealthTimer/NotificationManager.swift`

**Step 1: Add UNUserNotificationCenter protocol + injection**

```swift
protocol UNUserNotificationCenterProtocol {
    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)?)
    func removeAllPendingNotificationRequests()
}

extension UNUserNotificationCenter: UNUserNotificationCenterProtocol {}
```

- Add an initializer parameter with a default:
`init(exerciseManager: ExerciseManager, notificationCenter: UNUserNotificationCenterProtocol = UNUserNotificationCenter.current())`
- Store it and use it for test notifications (leave scheduling path on `UNUserNotificationCenter.current()` unless refactoring).

**Step 2: Add sendTestNotification(for:)**

- Build content identical to a normal reminder.
- Use a distinct identifier: `"EXERCISE_NOTIFICATION_TEST_\(exercise.id)_\(UUID().uuidString)"`.
- Use an immediate trigger (e.g. `UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)`).
- On add error, log.

**Step 3: Run tests (expect pass)**

Run: `xcodebuild test -scheme HealthTimer -destination 'platform=macOS'`
Expected: PASS.

**Step 4: Commit**

```bash
git add HealthTimer/HealthTimer/NotificationManager.swift
git commit -m "feat: add test notification helper"
```

---

### Task 5: Update PreferencesWindow UI + AppDelegate wiring

**Files:**
- Modify: `HealthTimer/HealthTimer/PreferencesWindow.swift`
- Modify: `HealthTimer/HealthTimer/AppDelegate.swift`

**Step 1: Update Preferences window size**

- Set the SwiftUI root `.frame(width: 640, height: 520)`.
- Update the NSWindow content rect to 640×520, and lock min/max to that size.

**Step 2: Update reminders row layout**

- Add `@State private var activeInfoExerciseId: String?`.
- Row layout: Name → Info button → Interval → Toggle → “Test”.
- Info button uses `Image(systemName: "info.circle")` and `.popover` with `instructionText`.
- “Test” button calls `remindersViewModel.sendTestNotification(id:)`.

**Step 3: Wire callbacks**

- `PreferencesWindow` init accepts `onTestNotification: (ExerciseDefinition) -> Void`.
- `AppDelegate` passes a closure calling `notificationManager.sendTestNotification(for:)`.

**Step 4: Manual verification**

- Preferences window opens at 640×520 and is not resizable.
- Footer text not clipped.
- Info popover shows instructions and stays open until dismissed.
- “Test” sends an immediate notification; Next menu status unchanged.

**Step 5: Commit**

```bash
git add HealthTimer/HealthTimer/PreferencesWindow.swift HealthTimer/HealthTimer/AppDelegate.swift
git commit -m "feat: polish reminders preferences ui"
```
