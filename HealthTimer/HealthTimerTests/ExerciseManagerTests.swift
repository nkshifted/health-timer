import XCTest
@testable import HealthTimer

final class ExerciseManagerTests: XCTestCase {
    func testNextDueDateUsesStableAnchorWhenNoLastFiredAt() {
        let manager = ExerciseManager()
        let exercise = manager.getExerciseList().first!
        let defaults = UserDefaults.standard

        defaults.removeObject(forKey: "exercise.\(exercise.id).lastFiredAt")
        defaults.removeObject(forKey: "exercise.\(exercise.id).anchorAt")
        defaults.removeObject(forKey: "exercise.\(exercise.id).intervalMinutes")
        defaults.removeObject(forKey: "exercise.\(exercise.id).enabled")

        let now = Date(timeIntervalSince1970: 1000)
        let firstDue = manager.nextDueDate(now: now)
        let later = now.addingTimeInterval(300)
        let secondDue = manager.nextDueDate(now: later)

        XCTAssertEqual(firstDue, secondDue)

        defaults.removeObject(forKey: "exercise.\(exercise.id).lastFiredAt")
        defaults.removeObject(forKey: "exercise.\(exercise.id).anchorAt")
        defaults.removeObject(forKey: "exercise.\(exercise.id).intervalMinutes")
        defaults.removeObject(forKey: "exercise.\(exercise.id).enabled")
    }
}
