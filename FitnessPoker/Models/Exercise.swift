import Foundation

struct Exercise: Identifiable, Codable, Equatable {
    let id = UUID()
    var name: String
    var description: String

    static let defaultExercises: [Exercise] = [
        Exercise(name: "Push-ups", description: "Standard push-ups"),
        Exercise(name: "Squats", description: "Air squats"),
        Exercise(name: "Burpees", description: "Full burpees"),
        Exercise(name: "Mountain Climbers", description: "Mountain climber reps"),
        Exercise(name: "Jumping Jacks", description: "Jumping jacks"),
        Exercise(name: "Lunges", description: "Alternating lunges"),
        Exercise(name: "Plank Hold", description: "Hold plank position"),
        Exercise(name: "Sit-ups", description: "Standard sit-ups"),
        Exercise(name: "High Knees", description: "High knee running"),
        Exercise(name: "Tricep Dips", description: "Chair or bench tricep dips"),
        Exercise(name: "Wall Sit", description: "Wall sit hold"),
        Exercise(name: "Russian Twists", description: "Core rotation exercise")
    ]

    static func == (lhs: Exercise, rhs: Exercise) -> Bool {
        return lhs.id == rhs.id
    }
}

class ExerciseManager: ObservableObject {
    @Published var suitExercises: [Suit: Exercise] = [:]
    @Published var jokerExercise: Exercise = Exercise.defaultExercises[2]
    @Published var customExercises: [Exercise] = []
    @Published var allAvailableExercises: [Exercise] = []

    init() {
        loadExercises()
        resetToDefaults()
    }

    private func loadExercises() {
        allAvailableExercises = Exercise.defaultExercises + customExercises
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

    func addCustomExercise(name: String, description: String) {
        let newExercise = Exercise(name: name, description: description)
        customExercises.append(newExercise)
        allAvailableExercises = Exercise.defaultExercises + customExercises
    }

    func removeCustomExercise(_ exercise: Exercise) {
        customExercises.removeAll { $0.id == exercise.id }
        allAvailableExercises = Exercise.defaultExercises + customExercises

        // Update suit assignments if they were using the removed exercise
        for suit in Suit.allCases {
            if suitExercises[suit]?.id == exercise.id {
                suitExercises[suit] = Exercise.defaultExercises[0]
            }
        }
        if jokerExercise.id == exercise.id {
            jokerExercise = Exercise.defaultExercises[4]
        }
    }

    func updateCustomExercise(_ exercise: Exercise, name: String, description: String) {
        if let index = customExercises.firstIndex(where: { $0.id == exercise.id }) {
            customExercises[index].name = name
            customExercises[index].description = description
            allAvailableExercises = Exercise.defaultExercises + customExercises
        }
    }
}