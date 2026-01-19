import Foundation
import OSLog

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
    private let onTestNotification: (ExerciseDefinition) -> Void
    private let logger = Logger(subsystem: "com.healthtimer.app", category: "preferences")
    private var definitionsById: [String: ExerciseDefinition] = [:]

    init(exerciseManager: ExerciseManager, onScheduleChange: @escaping () -> Void, onTestNotification: @escaping (ExerciseDefinition) -> Void = { _ in }) {
        self.exerciseManager = exerciseManager
        self.onScheduleChange = onScheduleChange
        self.onTestNotification = onTestNotification
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

    func instructionText(for id: String) -> String {
        guard let definition = definitionsById[id] else {
            logger.warning("Missing instructions for exercise id: \(id, privacy: .public)")
            return "Instructions unavailable."
        }
        let trimmed = definition.instructions.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            logger.warning("Empty instructions for exercise id: \(id, privacy: .public)")
            return "Instructions unavailable."
        }
        return definition.instructions
    }

    func sendTestNotification(id: String) {
        guard let definition = definitionsById[id] else {
            logger.warning("Missing exercise for test notification: \(id, privacy: .public)")
            return
        }
        onTestNotification(definition)
    }

    private func load() {
        let definitions = exerciseManager.getExerciseList()
        definitionsById = Dictionary(uniqueKeysWithValues: definitions.map { ($0.id, $0) })
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
