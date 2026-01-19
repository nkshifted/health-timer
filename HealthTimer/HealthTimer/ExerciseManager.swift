import Foundation

struct Exercise {
    let name: String
    let instructions: String
}

class ExerciseManager {
    private let exercises: [Exercise] = [
        Exercise(
            name: "Ankle Pumps",
            instructions: "Flex your feet up and down 10-15 times while seated. This activates the calf muscle pump to improve venous return from your lower legs."
        ),
        Exercise(
            name: "Calf Raises",
            instructions: "Stand and rise up on your toes, hold for 2 seconds, then lower. Repeat 10-15 times to strengthen calf muscles and promote circulation."
        ),
        Exercise(
            name: "Seated Knee Extensions",
            instructions: "While seated, straighten one knee to extend your leg, hold for 3 seconds, then lower. Alternate legs for 10 repetitions each to engage quadriceps and improve blood flow."
        ),
        Exercise(
            name: "Hip Circles",
            instructions: "Stand and make circular motions with your hips, 10 circles in each direction. This mobilizes hip joints and activates gluteal muscles to prevent stiffness."
        ),
        Exercise(
            name: "Toe Raises",
            instructions: "While seated or standing, lift your toes off the ground while keeping heels down. Hold for 2 seconds, repeat 10-15 times to strengthen anterior tibialis muscles."
        ),
        Exercise(
            name: "Leg Swings",
            instructions: "Stand on one leg and swing the other leg forward and backward 10 times, then switch legs. This dynamic movement improves circulation and hip mobility."
        )
    ]

    var currentIndex: Int {
        get {
            UserDefaults.standard.integer(forKey: "currentExerciseIndex")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "currentExerciseIndex")
        }
    }

    func getCurrentExercise() -> Exercise {
        return exercises[currentIndex]
    }

    func advanceToNextExercise() {
        currentIndex = (currentIndex + 1) % exercises.count
    }

    func getExerciseList() -> [Exercise] {
        return exercises
    }
}
