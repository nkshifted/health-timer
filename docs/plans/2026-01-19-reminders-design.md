# Reminders Configuration + Menu Controls Design

## Summary
Add a fixed list of desk-exercise reminders with per-exercise interval configuration, a single reminder stream with fair selection, and menu controls for start/stop plus next reminder status.

## Scheduling Semantics
- Fixed built-in list of exercises; no custom add/remove in this version.
- Each exercise has its own interval.
- An exercise is **due** if `now - lastFiredAt >= interval`.
- Single reminder stream: when multiple exercises are due, pick one using fair rotation (prefer longest overdue, avoid recent repeats).
- “Time since last fired” governs due status; pauses/snoozes effectively delay future reminders.

## UI / UX
### Menu Bar
- Show next reminder name + time remaining (e.g., “Next: Ankle Pumps · 12m”).
- Start/Pause control for the reminder stream.
- Snooze stays.
- Preferences + Quit remain.

### Preferences → Reminders
- Fixed list of exercises.
- Per exercise:
  - Interval preset picker: 15m / 30m / 45m / 1h / 90m / 2h
  - Enable/disable toggle
- Changes reschedule the next reminder immediately.

## Data Model / Storage
- Exercise model includes: `id`, `name`, `instructions`, `defaultInterval`, `enabled`, `lastFiredAt`.
- Store per-exercise `interval` and `enabled` in `UserDefaults` keyed by exercise id.
- Persist `lastFiredAt` so the schedule survives app restarts.

## Scheduling Flow
- `NotificationManager` asks `ExerciseManager` for:
  - next due exercise (if any)
  - otherwise next due time across enabled exercises
- If due list non-empty: choose with fairness strategy (longest overdue, avoid recent history list).
- On notification action: update `lastFiredAt` and reschedule.
- Pause: cancel scheduled notifications and stop scheduling.
- Resume: recompute and schedule next reminder.

## Error Handling & Logging
- Log scheduling decisions and notification errors via unified logging (subsystem `com.healthtimer.app`).

## Testing (manual)
- Change interval presets → next reminder updates.
- Enable/disable exercise → next reminder updates.
- Pause → no notifications scheduled; Resume → next reminder scheduled.
- Multiple due exercises → verify rotation (no immediate repeats).

