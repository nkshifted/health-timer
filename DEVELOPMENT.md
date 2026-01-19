# Development Guide

## Project Structure

```
HealthTimer/
├── HealthTimer.xcodeproj/       # Xcode project file
│   └── project.pbxproj
├── HealthTimer/                  # Source code
│   ├── AppDelegate.swift         # Main app entry point, menu bar setup
│   ├── ExerciseManager.swift     # Exercise data and cycling logic
│   ├── NotificationManager.swift # Notification scheduling and work hours
│   ├── PreferencesWindow.swift   # SwiftUI preferences interface
│   ├── Info.plist               # App configuration
│   ├── HealthTimer.entitlements # Sandbox permissions
│   └── Assets.xcassets/         # App icons
```

## Building

### Prerequisites
- macOS 13.0 or later
- Xcode 15.0 or later

### Build Commands

```bash
# Open in Xcode
open HealthTimer/HealthTimer.xcodeproj

# Build from command line
xcodebuild -project HealthTimer/HealthTimer.xcodeproj -scheme HealthTimer -configuration Debug build

# Build release version
xcodebuild -project HealthTimer/HealthTimer.xcodeproj -scheme HealthTimer -configuration Release build

# Clean build artifacts
xcodebuild -project HealthTimer/HealthTimer.xcodeproj -scheme HealthTimer clean
```

### NPM Scripts

```bash
npm run build    # Build release version
npm run clean    # Clean build artifacts
npm run archive  # Create distributable archive
```

## Architecture

### AppDelegate
- Main entry point with `@main` attribute
- Creates menu bar status item
- Manages app lifecycle
- Requests notification permissions
- Handles notification delegate callbacks

### ExerciseManager
- Stores 6 evidence-based exercises
- Cycles through exercises using UserDefaults
- Each exercise has name and 2-sentence instruction

### NotificationManager
- Schedules notifications using UNUserNotificationCenter
- Respects work hours (configurable, default 9 AM - 5 PM)
- Implements timer intervals (15/30/45/60 minutes)
- Handles snooze functionality (5 minute delay)
- Auto-schedules next notification after each delivery

### PreferencesWindow
- SwiftUI-based preferences interface
- Timer interval picker
- Work hours start/end time pickers
- Launch at login toggle (SMAppService API)
- Persists settings to UserDefaults

## Key Features

### Menu Bar Only App
- `LSUIElement = true` in Info.plist
- No dock icon
- Persistent menu bar presence

### Notification System
- Uses UNUserNotificationCenter for reliability
- Custom notification category with snooze action
- Notifications only during work hours
- Automatic rescheduling

### Data Persistence
- UserDefaults keys:
  - `timerInterval` (Int, default 30)
  - `workHoursStart` (Int, default 9)
  - `workHoursEnd` (Int, default 17)
  - `currentExerciseIndex` (Int, tracks cycle position)

### Launch at Login
- Uses ServiceManagement framework (macOS 13+)
- SMAppService.mainApp.register() / unregister()
- Toggle in preferences window

## Testing Locally

1. Open project in Xcode
2. Select "HealthTimer" scheme
3. Build and Run (Cmd+R)
4. Grant notification permissions when prompted
5. Look for timer icon in menu bar
6. Click icon to access menu
7. Open Preferences to configure

### Manual Testing Checklist

- [ ] App appears in menu bar
- [ ] Notification permission requested on first launch
- [ ] Notifications appear at configured interval
- [ ] Notifications only during work hours
- [ ] Snooze delays notification by 5 minutes
- [ ] Preferences persist across app restarts
- [ ] Timer interval changes take effect
- [ ] Work hours changes respected
- [ ] Launch at login toggle works
- [ ] Exercises cycle through all 6 types

## Troubleshooting

### No notifications appearing
- Check System Settings > Notifications > HealthTimer is enabled
- Verify current time is within work hours
- Check Console.app for error messages

### Menu bar icon not showing
- Verify LSUIElement is set to true in Info.plist
- Check if app is running (Activity Monitor)

### Build failures
- Ensure deployment target matches macOS version (13.0)
- Verify all source files are added to target
- Clean build folder (Shift+Cmd+K in Xcode)

## Code Quality

### Error Handling
- All errors are logged to console
- Graceful degradation when permissions denied
- No silent failures

### Memory Management
- Uses ARC (Automatic Reference Counting)
- No strong reference cycles
- Weak delegate references

### Thread Safety
- Main thread for all UI operations
- Notification callbacks handled on main queue
- DispatchQueue.main.async for UI updates
