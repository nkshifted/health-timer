import Foundation

class ExerciseManager {
    private let exercises: [ExerciseDefinition] = [
        ExerciseDefinition(
            id: "ankle-pumps",
            name: "Ankle Pumps",
            instructions: "Flex your feet up and down 10-15 times while seated. This activates the calf muscle pump to improve venous return from your lower legs.",
            defaultIntervalMinutes: 30
        ),
        ExerciseDefinition(
            id: "calf-raises",
            name: "Calf Raises",
            instructions: "Stand and rise up on your toes, hold for 2 seconds, then lower. Repeat 10-15 times to strengthen calf muscles and promote circulation.",
            defaultIntervalMinutes: 30
        ),
        ExerciseDefinition(
            id: "seated-knee-extensions",
            name: "Seated Knee Extensions",
            instructions: "While seated, straighten one knee to extend your leg, hold for 3 seconds, then lower. Alternate legs for 10 repetitions each to engage quadriceps and improve blood flow.",
            defaultIntervalMinutes: 30
        ),
        ExerciseDefinition(
            id: "hip-circles",
            name: "Hip Circles",
            instructions: "Stand and make circular motions with your hips, 10 circles in each direction. This mobilizes hip joints and activates gluteal muscles to prevent stiffness.",
            defaultIntervalMinutes: 30
        ),
        ExerciseDefinition(
            id: "toe-raises",
            name: "Toe Raises",
            instructions: "While seated or standing, lift your toes off the ground while keeping heels down. Hold for 2 seconds, repeat 10-15 times to strengthen anterior tibialis muscles.",
            defaultIntervalMinutes: 30
        ),
        ExerciseDefinition(
            id: "leg-swings",
            name: "Leg Swings",
            instructions: "Stand on one leg and swing the other leg forward and backward 10 times, then switch legs. This dynamic movement improves circulation and hip mobility.",
            defaultIntervalMinutes: 30
        )
    ]

    private let userDefaults = UserDefaults.standard
    private let recentHistoryKey = "exerciseRecentHistory"
    private let currentIndexKey = "currentExerciseIndex"

    var currentIndex: Int {
        get {
            let index = userDefaults.integer(forKey: currentIndexKey)
            if index >= exercises.count { return 0 }
            return index
        }
        set {
            userDefaults.set(newValue, forKey: currentIndexKey)
        }
    }

    func getCurrentExercise() -> ExerciseDefinition {
        let index = min(max(currentIndex, 0), exercises.count - 1)
        return exercises[index]
    }

    func advanceToNextExercise() {
        currentIndex = (currentIndex + 1) % exercises.count
    }

    func getExerciseList() -> [ExerciseDefinition] {
        exercises
    }

    func stateById() -> [String: ExerciseState] {
        var state: [String: ExerciseState] = [:]
        for exercise in exercises {
            let intervalKey = intervalMinutesKey(for: exercise.id)
            let enabledKey = enabledKey(for: exercise.id)
            let lastFiredKey = lastFiredAtKey(for: exercise.id)

            let interval = userDefaults.integer(forKey: intervalKey)
            let storedInterval = interval > 0 ? interval : exercise.defaultIntervalMinutes
            let enabled: Bool
            if userDefaults.object(forKey: enabledKey) == nil {
                enabled = true
            } else {
                enabled = userDefaults.bool(forKey: enabledKey)
            }
            let lastFiredAt = userDefaults.object(forKey: lastFiredKey) as? Date

            state[exercise.id] = ExerciseState(intervalMinutes: storedInterval, enabled: enabled, lastFiredAt: lastFiredAt)
        }
        return state
    }

    func updateInterval(id: String, minutes: Int) {
        userDefaults.set(minutes, forKey: intervalMinutesKey(for: id))
    }

    func updateEnabled(id: String, enabled: Bool) {
        userDefaults.set(enabled, forKey: enabledKey(for: id))
    }

    func markFired(id: String, at: Date) {
        userDefaults.set(at, forKey: lastFiredAtKey(for: id))
    }

    func nextDueExercise(now: Date) -> ExerciseDefinition? {
        let scheduler = ReminderScheduler(
            exercises: exercises,
            stateById: stateById(),
            recentHistory: recentHistory()
        )
        return scheduler.nextDueExercise(now: now)
    }

    func nextDueDate(now: Date) -> Date? {
        let scheduler = ReminderScheduler(
            exercises: exercises,
            stateById: stateById(),
            recentHistory: recentHistory()
        )
        return scheduler.nextDueDate(now: now)
    }

    func recentHistory() -> [String] {
        userDefaults.stringArray(forKey: recentHistoryKey) ?? []
    }

    func updateRecentHistory(with id: String) {
        var history = recentHistory().filter { $0 != id }
        history.append(id)
        if history.count > 2 {
            history = Array(history.suffix(2))
        }
        userDefaults.set(history, forKey: recentHistoryKey)
    }

    private func intervalMinutesKey(for id: String) -> String {
        "exercise.\(id).intervalMinutes"
    }

    private func enabledKey(for id: String) -> String {
        "exercise.\(id).enabled"
    }

    private func lastFiredAtKey(for id: String) -> String {
        "exercise.\(id).lastFiredAt"
    }
}
