# Reminders UI Polish Design

## Goal
Improve the Preferences window usability and add per-reminder affordances without changing scheduling behavior.

## Requirements
1. Preferences window opens larger and is **fixed size** (not resizable).
2. Add a **Test** button per reminder that fires a real notification immediately **without** affecting scheduling state.
3. Add an **Info** button per reminder that shows exercise instructions in a popover.
4. Defer categories and hydration; no category UI now.

## UI Changes
- Preferences window opens at a larger fixed size (e.g., 640×520).
- Each reminder row shows:
  - Name (text)
  - Info button (ⓘ) that opens a popover with instructions
  - Interval picker
  - Enabled toggle
  - Test button
- Footer text remains visible (no clipping).

## Data Flow
- `RemindersViewModel` builds `exercises` from `ExerciseManager.getExerciseList()` and provides `instructionsById` map.
- The Info button reads instructions via the map and shows a popover.
- Test button invokes a callback passed from `AppDelegate` → `PreferencesWindow` → `RemindersViewModel` → row action.
- `NotificationManager.sendTestNotification(for:)` sends a notification immediately and **does not**:
  - update ExerciseManager state
  - update recent history
  - reschedule notifications
  - update the menu status

## Notification Behavior
- Test notification uses the same title/body as a normal reminder.
- Use a distinct request identifier (e.g., `EXERCISE_NOTIFICATION_TEST_<id>`).
- Errors from UNUserNotificationCenter add() are logged.

## Error Handling
- If an exercise id is missing or instructions are empty, the Info popover shows a fallback (“Instructions unavailable.”) and logs a warning.
- Test notification failures log the error (no retries).

## Manual Verification
- Preferences window opens at fixed larger size; header/footer visible.
- Info button opens popover with correct instructions.
- Test button fires notification immediately; content matches reminder.
- Test action does **not** change the “Next” menu status.
- Interval/toggle changes still update scheduling and menu status.

## Follow‑ups
- Add hydration reminder and category grouping in a future change (not in scope here).
