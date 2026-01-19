import Foundation

final class RemindersViewModel: ObservableObject {
    struct ExerciseRow: Identifiable {
        let id: String
        let name: String
        var intervalMinutes: Int
        var enabled: Bool
    }

    @Published var exercises: [ExerciseRow] = []

    private let exerciseManager: ExerciseManager
    private let onScheduleChange: () -> Void

    init(exerciseManager: ExerciseManager, onScheduleChange: @escaping () -> Void) {
        self.exerciseManager = exerciseManager
        self.onScheduleChange = onScheduleChange
        load()
    }

    func updateInterval(id: String, minutes: Int) {
        if let index = exercises.firstIndex(where: { $0.id == id }) {
            exercises[index].intervalMinutes = minutes
        }
        exerciseManager.updateInterval(id: id, minutes: minutes)
        onScheduleChange()
    }

    func updateEnabled(id: String, enabled: Bool) {
        if let index = exercises.firstIndex(where: { $0.id == id }) {
            exercises[index].enabled = enabled
        }
        exerciseManager.updateEnabled(id: id, enabled: enabled)
        onScheduleChange()
    }

    private func load() {
        let definitions = exerciseManager.getExerciseList()
        let state = exerciseManager.stateById()
        exercises = definitions.map { definition in
            let storedState = state[definition.id]
            return ExerciseRow(
                id: definition.id,
                name: definition.name,
                intervalMinutes: storedState?.intervalMinutes ?? definition.defaultIntervalMinutes,
                enabled: storedState?.enabled ?? true
            )
        }
    }
}
