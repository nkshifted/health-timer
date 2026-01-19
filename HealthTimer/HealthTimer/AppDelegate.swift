import Cocoa
import OSLog
import SwiftUI
import UserNotifications

private let logger = Logger(subsystem: "com.healthtimer.app", category: "app")

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var notificationManager: NotificationManager!
    private var exerciseManager: ExerciseManager!
    private var preferencesWindow: NSWindow?
    private var nextReminderItem: NSMenuItem?
    private var toggleRemindersItem: NSMenuItem?
    private var statusUpdateTimer: Timer?

    override init() {
        super.init()
        logger.info("AppDelegate init")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("applicationDidFinishLaunching")
        exerciseManager = ExerciseManager()
        notificationManager = NotificationManager(exerciseManager: exerciseManager)

        setupMenuBar()
        requestNotificationPermission()
        notificationManager.scheduleNextNotification()
        updateMenuStatus()
    }

    private func setupMenuBar() {
        logger.info("setupMenuBar start")
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Health Timer")
            if image == nil {
                button.title = "HT"
                logger.info("status item image is nil; using title fallback")
            } else {
                button.image = image
                button.title = ""
            }
            logger.info("status item button created")
        } else {
            logger.error("status item button is nil")
        }

        let menu = NSMenu()

        let nextItem = NSMenuItem(title: "No upcoming reminders", action: nil, keyEquivalent: "")
        nextItem.isEnabled = false
        nextReminderItem = nextItem
        menu.addItem(nextItem)

        let toggleItem = NSMenuItem(title: "Pause Reminders", action: #selector(toggleReminders), keyEquivalent: "p")
        toggleRemindersItem = toggleItem
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Preferences", action: #selector(openPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Snooze (5 min)", action: #selector(snoozeNotification), keyEquivalent: "s"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu

        statusUpdateTimer?.invalidate()
        statusUpdateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateMenuStatus()
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                UNUserNotificationCenter.current().delegate = self
            } else if let error = error {
                logger.error("Notification permission error: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    @objc private func openPreferences() {
        if preferencesWindow == nil {
            let contentView = PreferencesWindow(
                exerciseManager: exerciseManager,
                onScheduleChange: { [weak self] in
                    self?.notificationManager.scheduleNextNotification()
                    self?.updateMenuStatus()
                }
            )
            preferencesWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 520, height: 430),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            preferencesWindow?.title = "Preferences"
            preferencesWindow?.contentView = NSHostingView(rootView: contentView)
            preferencesWindow?.center()
            preferencesWindow?.isReleasedWhenClosed = false
        }

        preferencesWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func snoozeNotification() {
        let exercise = exerciseManager.getCurrentExercise()
        notificationManager.snooze(exercise: exercise, preserveIndex: exerciseManager.currentIndex)
        updateMenuStatus()
    }

    @objc private func toggleReminders() {
        if notificationManager.isPaused() {
            notificationManager.resume()
        } else {
            notificationManager.pause()
        }
        updateMenuStatus()
    }

    private func updateMenuStatus() {
        guard let nextReminderItem = nextReminderItem,
              let toggleRemindersItem = toggleRemindersItem else { return }

        if notificationManager.isPaused() {
            nextReminderItem.title = "Paused"
            toggleRemindersItem.title = "Start Reminders"
            return
        }

        toggleRemindersItem.title = "Pause Reminders"

        let now = Date()
        if let status = notificationManager.nextReminderStatus(now: now) {
            let remaining = max(0, status.fireDate.timeIntervalSince(now))
            let minutes = Int(remaining / 60)
            if minutes < 60 {
                nextReminderItem.title = "Next: \(status.name) · \(minutes)m"
            } else {
                let hours = minutes / 60
                let remainder = minutes % 60
                if remainder == 0 {
                    nextReminderItem.title = "Next: \(status.name) · \(hours)h"
                } else {
                    nextReminderItem.title = "Next: \(status.name) · \(hours)h \(remainder)m"
                }
            }
            return
        }

        nextReminderItem.title = "No upcoming reminders"
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
        let notification = response.notification
        let userInfo = notification.request.content.userInfo
        let isSnooze = userInfo["isSnooze"] as? Bool ?? false

        if response.actionIdentifier == "SNOOZE_ACTION" {
            let exerciseName = notification.request.content.title.replacingOccurrences(of: "Time for: ", with: "")
            let exerciseInstructions = notification.request.content.body
            let exerciseId = exerciseName.lowercased().replacingOccurrences(of: " ", with: "-")
            let exercise = ExerciseDefinition(id: exerciseId, name: exerciseName, instructions: exerciseInstructions, defaultIntervalMinutes: 0)
            notificationManager.snooze(exercise: exercise, preserveIndex: exerciseManager.currentIndex)
            updateMenuStatus()
        } else if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            if !isSnooze {
                exerciseManager.advanceToNextExercise()
            }
            notificationManager.scheduleNextNotification()
            updateMenuStatus()
        }
        completionHandler()
    }
}
