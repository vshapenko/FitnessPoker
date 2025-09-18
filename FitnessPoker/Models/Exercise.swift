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
    @Published var jokerExercises: [String: Exercise] = [:]
    @Published var customExercises: [Exercise] = []
    @Published var allAvailableExercises: [Exercise] = []

    private let jokerIds = ["Joker 1", "Joker 2"]

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
        jokerExercises = [
            jokerIds[0]: defaultExercises[4],
            jokerIds[1]: defaultExercises[5]
        ]
    }

    func setExercise(for suit: Suit, exercise: Exercise) {
        suitExercises[suit] = exercise
    }

    func setJokerExercise(for identifier: String, exercise: Exercise) {
        jokerExercises[identifier] = exercise
    }

    func getExercise(for card: Card) -> Exercise? {
        if let jokerId = card.jokerIdentifier {
            return jokerExercises[jokerId]
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
        // Update joker assignments if they were using the removed exercise
        for id in jokerIds {
            if jokerExercises[id]?.id == exercise.id {
                jokerExercises[id] = Exercise.defaultExercises[4]
            }
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