import XCTest
@testable import HealthTimer

final class RemindersViewModelTests: XCTestCase {
    func testInstructionTextReturnsStoredInstructions() {
        let viewModel = RemindersViewModel(
            exerciseManager: ExerciseManager(),
            onScheduleChange: {},
            onTestNotification: { _ in }
        )

        let definition = ExerciseManager().getExerciseList().first!
        let text = viewModel.instructionText(for: definition.id)

        XCTAssertEqual(text, definition.instructions)
    }

    func testInstructionTextFallsBackForUnknownId() {
        let viewModel = RemindersViewModel(
            exerciseManager: ExerciseManager(),
            onScheduleChange: {},
            onTestNotification: { _ in }
        )

        let text = viewModel.instructionText(for: "missing-id")
        XCTAssertEqual(text, "Instructions unavailable.")
    }

    func testSendTestNotificationUsesCallbackDefinition() {
        let expectation = expectation(description: "test notification callback")
        var capturedId: String?

        let manager = ExerciseManager()
        let viewModel = RemindersViewModel(
            exerciseManager: manager,
            onScheduleChange: {},
            onTestNotification: { exercise in
                capturedId = exercise.id
                expectation.fulfill()
            }
        )

        let definition = manager.getExerciseList().first!
        viewModel.sendTestNotification(id: definition.id)

        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(capturedId, definition.id)
    }
}
