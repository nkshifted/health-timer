import XCTest
import UserNotifications
@testable import HealthTimer

final class NotificationManagerTests: XCTestCase {
    private final class FakeNotificationCenter: UNUserNotificationCenterProtocol {
        var lastRequest: UNNotificationRequest?

        func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: (@Sendable (Error?) -> Void)?) {
            lastRequest = request
            completionHandler?(nil)
        }

        func removeAllPendingNotificationRequests() {}
    }

    func testSendTestNotificationBuildsImmediateRequest() {
        let fakeCenter = FakeNotificationCenter()
        let manager = NotificationManager(exerciseManager: ExerciseManager(), notificationCenter: fakeCenter)
        let exercise = ExerciseManager().getExerciseList().first!

        manager.sendTestNotification(for: exercise)

        let request = fakeCenter.lastRequest
        XCTAssertNotNil(request)
        XCTAssertTrue(request!.identifier.hasPrefix("EXERCISE_NOTIFICATION_TEST_"))
        XCTAssertEqual(request!.content.title, "Time for: \(exercise.name)")
        XCTAssertEqual(request!.content.body, exercise.instructions)
    }

    func testHandleDueReminderMarksFiredAndClearsScheduledReminder() {
        let defaults = UserDefaults.standard
        let exerciseManager = ExerciseManager()
        let manager = NotificationManager(exerciseManager: exerciseManager)
        let exercise = exerciseManager.getExerciseList().first!
        let fireDate = Date(timeIntervalSince1970: 1000)

        defaults.removeObject(forKey: "remindersPaused")
        defaults.removeObject(forKey: "exerciseRecentHistory")
        defaults.removeObject(forKey: "exercise.\(exercise.id).lastFiredAt")
        defaults.removeObject(forKey: "scheduledReminder.exerciseId")
        defaults.removeObject(forKey: "scheduledReminder.fireDate")

        defaults.set(exercise.id, forKey: "scheduledReminder.exerciseId")
        defaults.set(fireDate, forKey: "scheduledReminder.fireDate")

        let advanced = manager.handleDueReminderIfNeeded(now: fireDate.addingTimeInterval(5))

        XCTAssertTrue(advanced)
        XCTAssertEqual(defaults.object(forKey: "exercise.\(exercise.id).lastFiredAt") as? Date, fireDate)
        XCTAssertEqual(defaults.stringArray(forKey: "exerciseRecentHistory"), [exercise.id])
        XCTAssertNil(defaults.object(forKey: "scheduledReminder.exerciseId"))
        XCTAssertNil(defaults.object(forKey: "scheduledReminder.fireDate"))

        defaults.removeObject(forKey: "exercise.\(exercise.id).lastFiredAt")
        defaults.removeObject(forKey: "exerciseRecentHistory")
        defaults.removeObject(forKey: "scheduledReminder.exerciseId")
        defaults.removeObject(forKey: "scheduledReminder.fireDate")
    }
}
