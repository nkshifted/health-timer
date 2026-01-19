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

        menu.addItem(NSMenuItem(title: "Preferences", action: #selector(openPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Snooze (5 min)", action: #selector(snoozeNotification), keyEquivalent: "s"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
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
            let contentView = PreferencesWindow()
            preferencesWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
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
        } else if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            if !isSnooze {
                exerciseManager.advanceToNextExercise()
            }
            notificationManager.scheduleNextNotification()
        }
        completionHandler()
    }
}
