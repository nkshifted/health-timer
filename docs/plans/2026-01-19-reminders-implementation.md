# Reminders Configuration + Menu Controls Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add fixed per-exercise reminder configuration, start/stop controls, and next-reminder status in the menu bar.

**Architecture:** Centralize scheduling in `NotificationManager` using per-exercise state managed by `ExerciseManager`. Use a single reminder stream with fairness selection when multiple exercises are due. Expose a small view-model for Preferences to edit intervals/enabled flags and trigger rescheduling.

**Tech Stack:** Swift, SwiftUI, AppKit (NSStatusItem), UserNotifications, UserDefaults, Unified Logging.

---

### Task 1: Add scheduling model tests (new test target)

**Files:**
- Create: `HealthTimer/HealthTimerTests/ReminderSchedulerTests.swift`
- Modify: `HealthTimer/HealthTimer.xcodeproj/project.pbxproj`

**Step 1: Add a test target to the Xcode project**
- Add a new unit test target `HealthTimerTests` (macOS Unit Testing Bundle).
- Ensure it links to the app target so tests can import the scheduling types.

**Step 2: Write failing tests for due selection and fairness**
Create `ReminderSchedulerTests.swift`:
```swift
import XCTest
@testable import HealthTimer

final class ReminderSchedulerTests: XCTestCase {
    func testNextDueExerciseChoosesMostOverdue() {
        let now = Date(timeIntervalSince1970: 1000)
        let exercises = [
            ExerciseDefinition(id: "ankle", name: "Ankle Pumps", instructions: "", defaultIntervalMinutes: 15),
            ExerciseDefinition(id: "calf", name: "Calf Raises", instructions: "", defaultIntervalMinutes: 120)
        ]
        let state = [
            "ankle": ExerciseState(intervalMinutes: 15, enabled: true, lastFiredAt: now.addingTimeInterval(-3600)),
            "calf": ExerciseState(intervalMinutes: 120, enabled: true, lastFiredAt: now.addingTimeInterval(-4000))
        ]
        let scheduler = ReminderScheduler(exercises: exercises, stateById: state, recentHistory: [])
        let next = scheduler.nextDueExercise(now: now)
        XCTAssertEqual(next?.id, "calf")
    }

    func testNextDueExerciseAvoidsRecentHistoryWhenMultipleDue() {
        let now = Date(timeIntervalSince1970: 1000)
        let exercises = [
            ExerciseDefinition(id: "a", name: "A", instructions: "", defaultIntervalMinutes: 15),
            ExerciseDefinition(id: "b", name: "B", instructions: "", defaultIntervalMinutes: 15),
            ExerciseDefinition(id: "c", name: "C", instructions: "", defaultIntervalMinutes: 15)
        ]
        let state = [
            "a": ExerciseState(intervalMinutes: 15, enabled: true, lastFiredAt: now.addingTimeInterval(-1200)),
            "b": ExerciseState(intervalMinutes: 15, enabled: true, lastFiredAt: now.addingTimeInterval(-1200)),
            "c": ExerciseState(intervalMinutes: 15, enabled: true, lastFiredAt: now.addingTimeInterval(-1200))
        ]
        let scheduler = ReminderScheduler(exercises: exercises, stateById: state, recentHistory: ["a", "c"])
        let next = scheduler.nextDueExercise(now: now)
        XCTAssertEqual(next?.id, "b")
    }

    func testNextDueDateReturnsSoonestWhenNoneDue() {
        let now = Date(timeIntervalSince1970: 1000)
        let exercises = [
            ExerciseDefinition(id: "a", name: "A", instructions: "", defaultIntervalMinutes: 15),
            ExerciseDefinition(id: "b", name: "B", instructions: "", defaultIntervalMinutes: 120)
        ]
        let state = [
            "a": ExerciseState(intervalMinutes: 15, enabled: true, lastFiredAt: now.addingTimeInterval(-100)),
            "b": ExerciseState(intervalMinutes: 120, enabled: true, lastFiredAt: now.addingTimeInterval(-200))
        ]
        let scheduler = ReminderScheduler(exercises: exercises, stateById: state, recentHistory: [])
        let nextDate = scheduler.nextDueDate(now: now)
        XCTAssertEqual(nextDate, now.addingTimeInterval(15 * 60 - 100))
    }
}
```

**Step 3: Run tests (expect fail)**
Run: `xcodebuild test -scheme HealthTimer -destination 'platform=macOS'`
Expected: FAIL (types not found).

**Step 4: Commit test target scaffolding**
```bash
git add HealthTimer/HealthTimerTests/ReminderSchedulerTests.swift HealthTimer/HealthTimer.xcodeproj/project.pbxproj
git commit -m "test: add reminder scheduler tests"
```

---

### Task 2: Implement reminder models + scheduler

**Files:**
- Create: `HealthTimer/HealthTimer/ReminderScheduler.swift`
- Modify: `HealthTimer/HealthTimer/ExerciseManager.swift`

**Step 1: Add models + scheduler (minimal to satisfy tests)**
Create `ReminderScheduler.swift`:
```swift
import Foundation

struct ExerciseDefinition: Identifiable {
    let id: String
    let name: String
    let instructions: String
    let defaultIntervalMinutes: Int
}

struct ExerciseState {
    var intervalMinutes: Int
    var enabled: Bool
    var lastFiredAt: Date?
}

struct ReminderScheduler {
    let exercises: [ExerciseDefinition]
    let stateById: [String: ExerciseState]
    let recentHistory: [String]

    func nextDueExercise(now: Date) -> ExerciseDefinition? {
        let due = exercises.compactMap { exercise -> (ExerciseDefinition, TimeInterval)? in
            guard let state = stateById[exercise.id], state.enabled else { return nil }
            let last = state.lastFiredAt ?? Date.distantPast
            let overdue = now.timeIntervalSince(last) - TimeInterval(state.intervalMinutes * 60)
            return overdue >= 0 ? (exercise, overdue) : nil
        }
        guard !due.isEmpty else { return nil }

        let filtered = due.filter { !recentHistory.contains($0.0.id) }
        let candidates = filtered.isEmpty ? due : filtered
        return candidates.max(by: { $0.1 < $1.1 })?.0
    }

    func nextDueDate(now: Date) -> Date? {
        let futureDates = exercises.compactMap { exercise -> Date? in
            guard let state = stateById[exercise.id], state.enabled else { return nil }
            let last = state.lastFiredAt ?? now
            return last.addingTimeInterval(TimeInterval(state.intervalMinutes * 60))
        }
        return futureDates.min()
    }
}
```

**Step 2: Update ExerciseManager to use new models**
- Replace `Exercise` with `ExerciseDefinition`.
- Store `ExerciseState` in `UserDefaults` using keys:
  - `exercise.<id>.intervalMinutes`
  - `exercise.<id>.enabled`
  - `exercise.<id>.lastFiredAt`
- Add helper:
```swift
func stateById() -> [String: ExerciseState]
func updateInterval(id: String, minutes: Int)
func updateEnabled(id: String, enabled: Bool)
func markFired(id: String, at: Date)
func nextDueExercise(now: Date) -> ExerciseDefinition?
func nextDueDate(now: Date) -> Date?
func recentHistory() -> [String]
func updateRecentHistory(with id: String)
```
- Implement fairness by keeping `recentHistory` in UserDefaults (e.g., last 2 IDs).

**Step 3: Run tests (expect pass)**
Run: `xcodebuild test -scheme HealthTimer -destination 'platform=macOS'`
Expected: PASS.

**Step 4: Commit**
```bash
git add HealthTimer/HealthTimer/ReminderScheduler.swift HealthTimer/HealthTimer/ExerciseManager.swift
git commit -m "feat: add reminder scheduler and per-exercise state"
```

---

### Task 3: Update NotificationManager for single stream + pause

**Files:**
- Modify: `HealthTimer/HealthTimer/NotificationManager.swift`

**Step 1: Add pause flag + helpers**
- Add `@AppStorage` equivalent using `UserDefaults`:
  - `isPaused` boolean (key: `remindersPaused`)
- Add methods:
```swift
func pause()
func resume()
func isPaused() -> Bool
func nextReminderStatus(now: Date) -> (name: String, fireDate: Date)?
```

**Step 2: Rewrite scheduling to use ExerciseManager**
- Replace `timerInterval` logic.
- Use `exerciseManager.nextDueExercise(now:)` and `nextDueDate(now:)`.
- If paused: remove pending notifications and return.
- Respect work hours: if next fire time falls outside work hours, schedule for next workday start.
- When scheduling, include `exerciseId` in `userInfo` and set notification content from that exercise.

**Step 3: Update snooze to preserve exercise id**
- Keep `exerciseId` in `userInfo` when snoozing.

**Step 4: Commit**
```bash
git add HealthTimer/HealthTimer/NotificationManager.swift
git commit -m "feat: single-stream scheduling with pause support"
```

---

### Task 4: Update AppDelegate menu (start/stop + status)

**Files:**
- Modify: `HealthTimer/HealthTimer/AppDelegate.swift`

**Step 1: Add menu items**
- Add `nextReminderItem` (disabled) at top.
- Add `toggleRemindersItem` (Start/Pause) and wire to new `@objc` action.
- Keep Snooze, Preferences, Quit.

**Step 2: Add timer to refresh menu status**
- Add a `Timer` that fires every 60s and calls `updateMenuStatus()`.
- `updateMenuStatus()` uses `notificationManager.nextReminderStatus(now:)` to set title:
  - “Next: {name} · {mm}m” or “Next: {name} · {hh}h {mm}m”
  - If paused: “Paused”
  - If none scheduled: “No upcoming reminders”

**Step 3: Commit**
```bash
git add HealthTimer/HealthTimer/AppDelegate.swift
git commit -m "feat: menu start/stop and next reminder status"
```

---

### Task 5: Preferences UI for per-exercise intervals

**Files:**
- Modify: `HealthTimer/HealthTimer/PreferencesWindow.swift`
- Create (optional): `HealthTimer/HealthTimer/RemindersViewModel.swift`

**Step 1: Add view model to read/write ExerciseManager state**
- Provide `@Published` list of exercises with current interval + enabled.
- On change, update `ExerciseManager` and trigger `notificationManager.scheduleNextNotification()` via injected callback.

**Step 2: Replace Timer Interval section**
- Add list rows with:
  - Name
  - Picker for presets: 15m/30m/45m/1h/90m/2h
  - Toggle for enabled

**Step 3: Commit**
```bash
git add HealthTimer/HealthTimer/PreferencesWindow.swift HealthTimer/HealthTimer/RemindersViewModel.swift
git commit -m "feat: per-exercise reminder configuration UI"
```

---

### Task 6: Manual verification

**Step 1: Build + run**
Run: `npm run archive` then open the app.

**Step 2: Manual checks**
- Changing an interval updates the “Next” menu status.
- Pause stops scheduling, Resume restarts.
- When multiple are due, reminders rotate (no immediate repeats).

**Step 3: Commit final adjustments**
```bash
git add -A
git commit -m "chore: finalize reminders configuration and menu status"
```

