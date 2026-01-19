import XCTest
@testable import HealthTimer

final class ReminderSchedulerTests: XCTestCase {
    func testNextDueExerciseChoosesMostOverdue() {
        let now = Date(timeIntervalSince1970: 1000)
        let exercises = [
            ExerciseDefinition(id: "ankle", name: "Ankle Pumps", instructions: "", defaultIntervalMinutes: 15),
            ExerciseDefinition(id: "calf", name: "Calf Raises", instructions: "", defaultIntervalMinutes: 120)
        ]
        let state = [
            "ankle": ExerciseState(intervalMinutes: 15, enabled: true, lastFiredAt: now.addingTimeInterval(-3600)),
            "calf": ExerciseState(intervalMinutes: 120, enabled: true, lastFiredAt: now.addingTimeInterval(-4000))
        ]
        let scheduler = ReminderScheduler(exercises: exercises, stateById: state, recentHistory: [])
        let next = scheduler.nextDueExercise(now: now)
        XCTAssertEqual(next?.id, "calf")
    }

    func testNextDueExerciseAvoidsRecentHistoryWhenMultipleDue() {
        let now = Date(timeIntervalSince1970: 1000)
        let exercises = [
            ExerciseDefinition(id: "a", name: "A", instructions: "", defaultIntervalMinutes: 15),
            ExerciseDefinition(id: "b", name: "B", instructions: "", defaultIntervalMinutes: 15),
            ExerciseDefinition(id: "c", name: "C", instructions: "", defaultIntervalMinutes: 15)
        ]
        let state = [
            "a": ExerciseState(intervalMinutes: 15, enabled: true, lastFiredAt: now.addingTimeInterval(-1200)),
            "b": ExerciseState(intervalMinutes: 15, enabled: true, lastFiredAt: now.addingTimeInterval(-1200)),
            "c": ExerciseState(intervalMinutes: 15, enabled: true, lastFiredAt: now.addingTimeInterval(-1200))
        ]
        let scheduler = ReminderScheduler(exercises: exercises, stateById: state, recentHistory: ["a", "c"])
        let next = scheduler.nextDueExercise(now: now)
        XCTAssertEqual(next?.id, "b")
    }

    func testNextDueDateReturnsSoonestWhenNoneDue() {
        let now = Date(timeIntervalSince1970: 1000)
        let exercises = [
            ExerciseDefinition(id: "a", name: "A", instructions: "", defaultIntervalMinutes: 15),
            ExerciseDefinition(id: "b", name: "B", instructions: "", defaultIntervalMinutes: 120)
        ]
        let state = [
            "a": ExerciseState(intervalMinutes: 15, enabled: true, lastFiredAt: now.addingTimeInterval(-100)),
            "b": ExerciseState(intervalMinutes: 120, enabled: true, lastFiredAt: now.addingTimeInterval(-200))
        ]
        let scheduler = ReminderScheduler(exercises: exercises, stateById: state, recentHistory: [])
        let nextDate = scheduler.nextDueDate(now: now)
        XCTAssertEqual(nextDate, now.addingTimeInterval(15 * 60 - 100))
    }
}
