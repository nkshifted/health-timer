import Foundation
import UserNotifications

protocol UNUserNotificationCenterProtocol {
    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: (@Sendable (Error?) -> Void)?)
    func removeAllPendingNotificationRequests()
}

extension UNUserNotificationCenter: UNUserNotificationCenterProtocol {}

class NotificationManager {
    private let exerciseManager: ExerciseManager
    private let notificationCenter: UNUserNotificationCenterProtocol
    private let pausedKey = "remindersPaused"
    private let scheduledExerciseIdKey = "scheduledReminder.exerciseId"
    private let scheduledFireDateKey = "scheduledReminder.fireDate"

    private var workHoursStart: Int {
        if UserDefaults.standard.object(forKey: "workHoursStart") == nil {
            return 9
        }
        return UserDefaults.standard.integer(forKey: "workHoursStart")
    }

    private var workHoursEnd: Int {
        if UserDefaults.standard.object(forKey: "workHoursEnd") == nil {
            return 17
        }
        return UserDefaults.standard.integer(forKey: "workHoursEnd")
    }

    init(exerciseManager: ExerciseManager, notificationCenter: UNUserNotificationCenterProtocol = UNUserNotificationCenter.current()) {
        self.exerciseManager = exerciseManager
        self.notificationCenter = notificationCenter
    }

    func pause() {
        UserDefaults.standard.set(true, forKey: pausedKey)
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        clearScheduledReminder()
    }

    func resume() {
        UserDefaults.standard.set(false, forKey: pausedKey)
        scheduleNextNotification()
    }

    func isPaused() -> Bool {
        UserDefaults.standard.bool(forKey: pausedKey)
    }

    func nextReminderStatus(now: Date) -> (name: String, fireDate: Date)? {
        guard !isPaused() else { return nil }
        guard let exercise = exerciseManager.nextDueExercise(now: now) else { return nil }
        guard let nextDueDate = exerciseManager.nextDueDate(now: now) else { return nil }

        let fireDate = max(now, nextDueDate)
        if isWithinWorkHours(date: fireDate) {
            return (exercise.name, fireDate)
        }
        return (exercise.name, nextWorkDayStart(from: fireDate))
    }

    func scheduleNextNotification() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        if isPaused() {
            clearScheduledReminder()
            return
        }

        let now = Date()

        guard let exercise = exerciseManager.nextDueExercise(now: now) else {
            clearScheduledReminder()
            return
        }
        guard let nextDueDate = exerciseManager.nextDueDate(now: now) else {
            clearScheduledReminder()
            return
        }

        let fireDate = max(now, nextDueDate)
        if isWithinWorkHours(date: fireDate) {
            scheduleNotification(for: exercise, at: fireDate, isSnooze: false)
            return
        }

        scheduleForNextWorkDay(exercise: exercise, from: fireDate)
    }

    func snooze(exercise: ExerciseDefinition, preserveIndex: Int) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        let fireDate = Date().addingTimeInterval(300)
        scheduleNotification(for: exercise, at: fireDate, isSnooze: true)
    }

    @discardableResult
    func handleDueReminderIfNeeded(now: Date = Date()) -> Bool {
        guard !isPaused() else { return false }
        guard let exerciseId = UserDefaults.standard.string(forKey: scheduledExerciseIdKey),
              let fireDate = UserDefaults.standard.object(forKey: scheduledFireDateKey) as? Date else {
            return false
        }
        guard fireDate <= now else { return false }

        exerciseManager.markFired(id: exerciseId, at: fireDate)
        exerciseManager.updateRecentHistory(with: exerciseId)
        clearScheduledReminder()
        return true
    }

    func sendTestNotification(for exercise: ExerciseDefinition) {
        let content = UNMutableNotificationContent()
        content.title = "Time for: \(exercise.name)"
        content.body = exercise.instructions
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "EXERCISE_NOTIFICATION_TEST_\(exercise.id)_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling test notification: \(error)")
            }
        }
    }

    private func scheduleForNextWorkDay(exercise: ExerciseDefinition, from date: Date) {
        let nextDate = nextWorkDayStart(from: date)
        scheduleNotification(for: exercise, at: nextDate, isSnooze: false)
    }

    private func scheduleNotification(for exercise: ExerciseDefinition, at date: Date, isSnooze: Bool) {
        let content = UNMutableNotificationContent()
        content.title = "Time for: \(exercise.name)"
        content.body = exercise.instructions
        content.sound = .default
        content.userInfo = ["exerciseId": exercise.id, "isSnooze": isSnooze]

        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "Snooze (5 min)",
            options: []
        )

        let category = UNNotificationCategory(
            identifier: "EXERCISE_REMINDER",
            actions: [snoozeAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = "EXERCISE_REMINDER"

        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        dateComponents.second = dateComponents.second ?? 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: "EXERCISE_NOTIFICATION",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
        recordScheduledReminder(exerciseId: exercise.id, fireDate: date)
    }

    private func isWithinWorkHours(date: Date) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        return hour >= workHoursStart && hour < workHoursEnd
    }

    private func nextWorkDayStart(from date: Date) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = workHoursStart
        components.minute = 0
        components.second = 0

        guard var nextDate = calendar.date(from: components) else { return date }
        if nextDate <= date {
            nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate) ?? nextDate
        }
        return nextDate
    }

    private func recordScheduledReminder(exerciseId: String, fireDate: Date) {
        UserDefaults.standard.set(exerciseId, forKey: scheduledExerciseIdKey)
        UserDefaults.standard.set(fireDate, forKey: scheduledFireDateKey)
    }

    private func clearScheduledReminder() {
        UserDefaults.standard.removeObject(forKey: scheduledExerciseIdKey)
        UserDefaults.standard.removeObject(forKey: scheduledFireDateKey)
    }
}
