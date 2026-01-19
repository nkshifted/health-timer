import Foundation
import UserNotifications

class NotificationManager {
    private let exerciseManager: ExerciseManager
    private var currentExercise: Exercise?

    private var timerInterval: Int {
        let interval = UserDefaults.standard.integer(forKey: "timerInterval")
        return interval > 0 ? interval : 30
    }

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

    init(exerciseManager: ExerciseManager) {
        self.exerciseManager = exerciseManager
    }

    func scheduleNextNotification() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)

        guard currentHour >= workHoursStart && currentHour < workHoursEnd else {
            scheduleForNextWorkDay()
            return
        }

        let exercise = exerciseManager.getCurrentExercise()
        currentExercise = exercise

        let content = UNMutableNotificationContent()
        content.title = "Time for: \(exercise.name)"
        content.body = exercise.instructions
        content.sound = .default
        content.userInfo = ["exerciseIndex": exerciseManager.currentIndex, "isSnooze": false]

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

        let triggerInterval = TimeInterval(timerInterval * 60)
        let triggerDate = calendar.date(byAdding: .second, value: Int(triggerInterval), to: now)!
        let triggerHour = calendar.component(.hour, from: triggerDate)

        if triggerHour < workHoursStart || triggerHour >= workHoursEnd {
            scheduleForNextWorkDay()
            return
        }

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: triggerInterval,
            repeats: false
        )

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
    }

    func snooze(exercise: Exercise, preserveIndex: Int) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        let content = UNMutableNotificationContent()
        content.title = "Time for: \(exercise.name)"
        content.body = exercise.instructions
        content.sound = .default
        content.categoryIdentifier = "EXERCISE_REMINDER"
        content.userInfo = ["exerciseIndex": preserveIndex, "isSnooze": true]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 300,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "EXERCISE_NOTIFICATION",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling snooze notification: \(error)")
            }
        }
    }

    private func scheduleForNextWorkDay() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = workHoursStart
        components.minute = 0
        components.second = 0

        guard var nextDate = calendar.date(from: components) else { return }

        if nextDate <= Date() {
            nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate) ?? nextDate
        }

        var dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: nextDate)
        dateComponents.second = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let exercise = exerciseManager.getCurrentExercise()
        currentExercise = exercise

        let content = UNMutableNotificationContent()
        content.title = "Time for: \(exercise.name)"
        content.body = exercise.instructions
        content.sound = .default
        content.categoryIdentifier = "EXERCISE_REMINDER"
        content.userInfo = ["exerciseIndex": exerciseManager.currentIndex, "isSnooze": false]

        let request = UNNotificationRequest(
            identifier: "EXERCISE_NOTIFICATION",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling next work day notification: \(error)")
            }
        }
    }
}
