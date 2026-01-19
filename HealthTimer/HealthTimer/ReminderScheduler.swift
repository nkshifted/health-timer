import Foundation

struct ExerciseDefinition: Identifiable {
    let id: String
    let name: String
    let instructions: String
    let defaultIntervalMinutes: Int
}

struct ExerciseState {
    var intervalMinutes: Int
    var enabled: Bool
    var lastFiredAt: Date?
}

struct ReminderScheduler {
    let exercises: [ExerciseDefinition]
    let stateById: [String: ExerciseState]
    let recentHistory: [String]

    func nextDueExercise(now: Date) -> ExerciseDefinition? {
        let due = exercises.compactMap { exercise -> (ExerciseDefinition, TimeInterval)? in
            guard let state = stateById[exercise.id], state.enabled else { return nil }
            let last = state.lastFiredAt ?? Date.distantPast
            let overdue = now.timeIntervalSince(last) - TimeInterval(state.intervalMinutes)
            return overdue >= 0 ? (exercise, overdue) : nil
        }

        guard !due.isEmpty else { return nil }

        let filtered = due.filter { !recentHistory.contains($0.0.id) }
        let candidates = filtered.isEmpty ? due : filtered
        return candidates.max(by: { $0.1 < $1.1 })?.0
    }

    func nextDueDate(now: Date) -> Date? {
        let futureDates = exercises.compactMap { exercise -> Date? in
            guard let state = stateById[exercise.id], state.enabled else { return nil }
            let last = state.lastFiredAt ?? now
            return last.addingTimeInterval(TimeInterval(state.intervalMinutes * 60))
        }
        return futureDates.min()
    }
}
