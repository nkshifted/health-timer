# HealthTimer

A macOS menu bar application that reminds you to perform desk exercises during work hours to prevent dependent edema and improve circulation.

## Overview

HealthTimer is designed for computer workers who spend long hours at their desks. Based on research recommendations for activity schedules to alleviate dependent edema and cold feet, this app sends periodic reminders to perform simple exercises that promote circulation and reduce the risk of venous pooling.

## Installation

1. Download the HealthTimer.app file
2. Move it to your Applications folder
3. Launch the app - it will appear in your menu bar (look for the timer icon)
4. Grant notification permissions when prompted

## Usage

### Menu Bar Controls

Click the timer icon in your menu bar to access:
- **Preferences** - Configure timer interval and work hours
- **Snooze (5 min)** - Delay the next reminder by 5 minutes
- **Quit** - Exit the application

### Preferences

- **Timer Interval**: Choose how often you receive reminders (15, 30, 45, or 60 minutes)
- **Work Hours**: Set your work schedule start and end times (notifications only appear during these hours)
- **Launch at Login**: Automatically start HealthTimer when you log in to macOS

### Exercise Reminders

The app cycles through six evidence-based exercises designed to improve lower limb circulation:

1. **Ankle Pumps** - Flex your feet up and down 10-15 times while seated. This activates the calf muscle pump to improve venous return from your lower legs.

2. **Calf Raises** - Stand and rise up on your toes, hold for 2 seconds, then lower. Repeat 10-15 times to strengthen calf muscles and promote circulation.

3. **Seated Knee Extensions** - While seated, straighten one knee to extend your leg, hold for 3 seconds, then lower. Alternate legs for 10 repetitions each to engage quadriceps and improve blood flow.

4. **Hip Circles** - Stand and make circular motions with your hips, 10 circles in each direction. This mobilizes hip joints and activates gluteal muscles to prevent stiffness.

5. **Toe Raises** - While seated or standing, lift your toes off the ground while keeping heels down. Hold for 2 seconds, repeat 10-15 times to strengthen anterior tibialis muscles.

6. **Leg Swings** - Stand on one leg and swing the other leg forward and backward 10 times, then switch legs. This dynamic movement improves circulation and hip mobility.

## Research Background

Prolonged sitting can lead to:
- Dependent edema (swelling in lower extremities)
- Reduced venous return
- Cold feet and hands
- Increased risk of deep vein thrombosis (DVT)

Regular movement breaks with exercises that activate leg muscles help maintain circulation and prevent these issues. The calf muscle acts as a "peripheral heart" that pumps blood back to the core when activated.

## Technical Details

- **Platform**: macOS 13.0 or later
- **Bundle ID**: com.healthtimer.app
- **Notifications**: Uses UserNotifications framework for reliable scheduling
- **Persistence**: Preferences stored in UserDefaults
- **Menu Bar Only**: No dock icon (LSUIElement = true)

## Citations

The exercise recommendations are based on occupational health guidelines for computer workers:
- American Heart Association recommendations for office workers
- OSHA ergonomic guidelines for sedentary work
- Clinical studies on calf muscle pump activation for venous return
- Occupational therapy protocols for preventing dependent edema in desk workers

## Building from Source

Requirements:
- Xcode 15.0 or later
- macOS 13.0 SDK

Build commands:
```bash
npm run build       # Build the application
npm run clean       # Clean build artifacts
npm run archive     # Create an archive for distribution
```

## License

MIT
