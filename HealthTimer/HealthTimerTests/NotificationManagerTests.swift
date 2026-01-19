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
}
