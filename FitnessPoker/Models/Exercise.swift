import Foundation

struct Exercise: Identifiable, Codable {
    let id = UUID()
    var name: String
    var description: String

    static let defaultExercises: [Exercise] = [
        Exercise(name: "Push-ups", description: "Standard push-ups"),
        Exercise(name: "Squats", description: "Air squats"),
        Exercise(name: "Burpees", description: "Full burpees"),
        Exercise(name: "Mountain Climbers", description: "Mountain climber reps"),
        Exercise(name: "Jumping Jacks", description: "Jumping jacks")
    ]
}

class ExerciseManager: ObservableObject {
    @Published var suitExercises: [Suit: Exercise] = [:]
    @Published var jokerExercise: Exercise = Exercise.defaultExercises[2]

    init() {
        resetToDefaults()
    }

    func resetToDefaults() {
        let defaultExercises = Exercise.defaultExercises
        suitExercises = [
            .hearts: defaultExercises[0],
            .diamonds: defaultExercises[1],
            .clubs: defaultExercises[2],
            .spades: defaultExercises[3]
        ]
        jokerExercise = defaultExercises[4]
    }

    func setExercise(for suit: Suit, exercise: Exercise) {
        suitExercises[suit] = exercise
    }

    func setJokerExercise(_ exercise: Exercise) {
        jokerExercise = exercise
    }

    func getExercise(for card: Card) -> Exercise? {
        if card.isJoker {
            return jokerExercise
        }
        guard let suit = card.suit else { return nil }
        return suitExercises[suit]
    }
}