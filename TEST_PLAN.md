# HealthTimer Test Plan

## Acceptance Criteria Verification

### AC1: Menu bar app with 30-minute notifications during work hours (9 AM - 5 PM)
**Priority: MUST**

**Test Steps:**
1. Build and run the application
2. Grant notification permissions when prompted
3. Verify timer icon appears in menu bar
4. Wait for initial notification (or set interval to 1 minute for testing)
5. Verify notification appears with exercise name and instructions
6. Check that notification appears during work hours only

**Expected Results:**
- App launches and displays menu bar icon
- First notification appears after configured interval (default 30 min)
- Notification title: "Time for: [Exercise Name]"
- Notification body: Contains exercise instructions
- No notifications before 9 AM or after 5 PM

**Verification Files:**
- `AppDelegate.swift:13-19` - App initialization
- `NotificationManager.swift:26-81` - Scheduling logic
- `NotificationManager.swift:33-36` - Work hours check

---

### AC2: Cycles through 6 evidence-based exercises
**Priority: MUST**

**Test Steps:**
1. Observe 6 consecutive notifications
2. Verify each shows a different exercise
3. Confirm all 6 exercises appear:
   - Ankle Pumps
   - Calf Raises
   - Seated Knee Extensions
   - Hip Circles
   - Toe Raises
   - Leg Swings
4. Verify 7th notification returns to first exercise

**Expected Results:**
- All 6 exercises shown in sequence
- Exercise cycling persists across app restarts
- Each exercise has meaningful instructions (2 sentences)

**Verification Files:**
- `ExerciseManager.swift:6-32` - Exercise definitions
- `ExerciseManager.swift:34-42` - Cycling logic

---

### AC3: Timer interval configurable (15/30/45/60 min), persists across restarts
**Priority: MUST**

**Test Steps:**
1. Click menu bar icon → Preferences
2. Change timer interval from 30 to 15 minutes
3. Close preferences
4. Verify next notification appears in 15 minutes
5. Quit and restart app
6. Open preferences
7. Verify interval still set to 15 minutes
8. Observe notification timing matches 15 minutes

**Expected Results:**
- Preferences window opens
- Timer interval picker shows options: 15, 30, 45, 60 minutes
- Selection saves to UserDefaults
- Setting persists after app restart
- Notifications fire at new interval

**Verification Files:**
- `PreferencesWindow.swift:5-6` - UserDefaults storage
- `PreferencesWindow.swift:18-25` - Timer interval picker
- `NotificationManager.swift:7-10` - Reading interval setting

---

### AC4: Snooze delays next reminder by 5 minutes
**Priority: SHOULD**

**Test Steps:**
1. Wait for notification to appear
2. Click "Snooze (5 min)" button in notification
3. Note current time
4. Wait 5 minutes
5. Verify new notification appears
6. Alternatively: Click menu bar icon → "Snooze (5 min)"
7. Verify notification appears 5 minutes later

**Expected Results:**
- Snooze button visible in notification
- Clicking snooze cancels current schedule
- New notification appears exactly 5 minutes later
- After snooze notification, normal interval resumes

**Verification Files:**
- `AppDelegate.swift:45-49` - Snooze action in category
- `AppDelegate.swift:83-86` - Notification action handler
- `AppDelegate.swift:68-70` - Menu snooze action
- `NotificationManager.swift:83-114` - Snooze implementation

---

### AC5: Work hours configurable, no notifications outside work hours
**Priority: SHOULD**

**Test Steps:**
1. Open Preferences
2. Set work hours to 10 AM - 4 PM
3. Close preferences
4. Set system time to 9:00 AM (or observe at 9 AM)
5. Verify no notification appears
6. Set system time to 10:00 AM (or wait until 10 AM)
7. Verify notification schedule starts
8. Set system time to 4:00 PM (or wait until 4 PM)
9. Verify notifications stop
10. Verify next notification scheduled for 10 AM next day

**Expected Results:**
- Work hours pickers show all hours (0-23)
- Settings save to UserDefaults
- No notifications before start time
- No notifications after end time
- Next-day scheduling works correctly

**Verification Files:**
- `PreferencesWindow.swift:7-8` - Work hours storage
- `PreferencesWindow.swift:27-49` - Hour pickers
- `NotificationManager.swift:12-20` - Reading work hours
- `NotificationManager.swift:33-36` - Work hours enforcement
- `NotificationManager.swift:116-134` - Next work day scheduling

---

## Additional Test Cases

### Launch at Login
**Test Steps:**
1. Open Preferences
2. Enable "Launch at Login"
3. Restart Mac
4. Verify app launches automatically
5. Disable toggle
6. Restart Mac
7. Verify app does NOT launch

**Expected Results:**
- Toggle works correctly
- SMAppService registers/unregisters
- Setting persists

**Verification Files:**
- `PreferencesWindow.swift:7` - Launch at login state
- `PreferencesWindow.swift:51-53` - Toggle UI
- `PreferencesWindow.swift:83-94` - SMAppService integration

---

### Menu Bar Functionality
**Test Steps:**
1. Click menu bar icon
2. Verify menu shows:
   - Preferences (⌘,)
   - Snooze (5 min) (⌘S)
   - Quit (⌘Q)
3. Test each menu item
4. Test keyboard shortcuts

**Expected Results:**
- All menu items functional
- Keyboard shortcuts work
- Preferences window opens
- Snooze triggers correctly
- Quit terminates app

**Verification Files:**
- `AppDelegate.swift:22-37` - Menu setup
- `AppDelegate.swift:49-66` - Preferences handler
- `AppDelegate.swift:68-70` - Snooze handler

---

### Notification Permissions
**Test Steps:**
1. First launch: Grant permissions
2. Verify notifications work
3. System Settings → Notifications → HealthTimer → Disable
4. Verify no notifications appear
5. Re-enable notifications
6. Verify notifications resume

**Expected Results:**
- Permission request on first launch
- Graceful handling when denied
- App works when permissions re-enabled

**Verification Files:**
- `AppDelegate.swift:39-47` - Permission request
- `Info.plist:27-28` - Usage description

---

### LSUIElement (Menu Bar Only)
**Test Steps:**
1. Launch app
2. Check Dock
3. Verify no app icon in Dock
4. Verify app in menu bar only

**Expected Results:**
- No Dock icon
- Only menu bar presence
- App in Activity Monitor

**Verification Files:**
- `Info.plist:25-26` - LSUIElement = true

---

## Performance Tests

### Memory Usage
- Monitor memory over 8-hour workday
- Should remain stable (< 50 MB)
- No memory leaks

### CPU Usage
- Idle CPU usage should be near 0%
- Brief spike during notification scheduling

### Notification Accuracy
- Notifications should fire within ±30 seconds of scheduled time
- No missed notifications during work hours

---

## Edge Cases

### System Sleep/Wake
- App should resume notifications after wake
- Timer should account for sleep time

### Time Zone Changes
- Work hours should respect system time zone
- Notifications adjust correctly

### Rapid Preference Changes
- Changing interval multiple times quickly
- Should handle gracefully without crashes

### Invalid Settings
- Work end < work start (shouldn't be possible with UI)
- 0 or negative intervals (defaults to 30)

---

## Manual Verification Checklist

- [ ] All Swift files compile without errors
- [ ] No force unwraps that could crash
- [ ] All delegate methods implemented
- [ ] UserDefaults keys consistent
- [ ] Notification categories registered
- [ ] UI responsive and functional
- [ ] No console errors during normal operation
- [ ] All menu actions work
- [ ] Exercise instructions complete
- [ ] Icon assets present
- [ ] Info.plist configured correctly
- [ ] Build settings appropriate for macOS 13.0+

---

## Regression Tests (After Code Changes)

1. Full build succeeds
2. App launches without errors
3. Menu bar icon appears
4. First notification fires
5. Preferences save and load
6. All 6 exercises cycle
7. Snooze functionality works
8. Work hours respected
9. Launch at login toggle works
10. App quits cleanly
