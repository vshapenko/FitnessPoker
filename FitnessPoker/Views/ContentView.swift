import SwiftUI

struct ContentView: View {
    @StateObject private var gameManager = GameManager()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                HeaderView(gameManager: gameManager)

                switch gameManager.gameState {
                case .setup:
                    SetupView(gameManager: gameManager)
                case .playing:
                    PlayingView(gameManager: gameManager)
                case .paused:
                    PausedView(gameManager: gameManager)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Fitness Poker")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct HeaderView: View {
    @ObservedObject var gameManager: GameManager

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Cards Remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(gameManager.deck.remainingCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Spacer()

                if gameManager.gameState == .playing || gameManager.gameState == .paused {
                    VStack(alignment: .trailing) {
                        Text("Game Time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(gameManager.timerManager.formattedTime)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(gameManager.timerManager.isExpired ? .red : .primary)
                    }
                }
            }

            if gameManager.gameState == .playing || gameManager.gameState == .paused {
                HStack {
                    Text("Limit: \(gameManager.timerManager.formattedTimeLimit)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button("Settings") {
                        gameManager.showingExerciseSetup = true
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .sheet(isPresented: $gameManager.showingExerciseSetup) {
            ExerciseSetupView(exerciseManager: gameManager.exerciseManager)
        }
    }
}

struct SetupView: View {
    @ObservedObject var gameManager: GameManager
    @State private var newPlayerName = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Players (Max 4)")
                .font(.title2)
                .fontWeight(.semibold)

            HStack {
                TextField("Player name", text: $newPlayerName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button("Add") {
                    if !newPlayerName.isEmpty && gameManager.teamManager.addPlayer(newPlayerName) {
                        newPlayerName = ""
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(newPlayerName.isEmpty || !gameManager.teamManager.canAddPlayer)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 10) {
                ForEach(gameManager.teamManager.players) { player in
                    PlayerCard(player: player) {
                        print("Remove player button tapped for: \(player.name)")
                        gameManager.teamManager.removePlayer(withId: player.id)
                        print("Players remaining: \(gameManager.teamManager.players.count)")
                    }
                }
            }

            TimerSetupView(timerManager: gameManager.timerManager)

            Button("Start Game") {
                print("Start Game button tapped!")
                print("Has players: \(gameManager.teamManager.hasPlayers)")
                print("Player count: \(gameManager.teamManager.players.count)")
                gameManager.startGame()
                print("Game state after start: \(gameManager.gameState)")
            }
            .buttonStyle(.borderedProminent)
            .font(.title2)
            .disabled(!gameManager.teamManager.hasPlayers)
        }
    }
}

struct PlayerCard: View {
    let player: Player
    let onRemove: () -> Void

    var body: some View {
        HStack {
            Text(player.name)
                .font(.subheadline)
                .lineLimit(1)

            Spacer()

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBlue).opacity(0.1))
        .cornerRadius(8)
    }
}

struct TimerSetupView: View {
    @ObservedObject var timerManager: TimerManager

    var body: some View {
        VStack(spacing: 10) {
            Text("Game Time Limit")
                .font(.headline)

            HStack(spacing: 15) {
                TimerButton(title: "No Limit", seconds: 0, timerManager: timerManager)
                TimerButton(title: "5m", seconds: 300, timerManager: timerManager)
                TimerButton(title: "10m", seconds: 600, timerManager: timerManager)
                TimerButton(title: "15m", seconds: 900, timerManager: timerManager)
            }

            Text("Selected: \(timerManager.formattedTimeLimit)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct TimerButton: View {
    let title: String
    let seconds: TimeInterval
    @ObservedObject var timerManager: TimerManager

    var body: some View {
        Button(action: {
            print("Timer button tapped: \(title), setting \(seconds) seconds")
            timerManager.setTimeLimit(seconds)
        }) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(timerManager.timeLimit == seconds ? .white : .primary)
        }
        .buttonStyle(.bordered)
        .background(timerManager.timeLimit == seconds ? Color.blue : Color.clear)
        .cornerRadius(8)
    }
}

struct PlayingView: View {
    @ObservedObject var gameManager: GameManager

    var body: some View {
        VStack(spacing: 20) {
            Text("Players")
                .font(.title2)
                .fontWeight(.semibold)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 15) {
                ForEach(gameManager.teamManager.players) { player in
                    PlayerGameCard(
                        player: player,
                        gameManager: gameManager,
                        isSelected: player.id == gameManager.teamManager.currentPlayer?.id
                    )
                }
            }

            HStack(spacing: 20) {
                Button("Pause Game") {
                    gameManager.pauseGame()
                }
                .buttonStyle(.bordered)

                Button("End Game") {
                    gameManager.endGame()
                }
                .buttonStyle(.borderedProminent)
                .foregroundColor(.red)
            }
            .padding(.top)
        }
    }
}

struct PlayerGameCard: View {
    let player: Player
    @ObservedObject var gameManager: GameManager
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text(player.name)
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Button(action: {
                    gameManager.teamManager.selectPlayer(player.id)
                }) {
                    Image(systemName: isSelected ? "person.fill" : "person")
                        .foregroundColor(isSelected ? .blue : .gray)
                }
            }

            if let card = player.currentCard {
                VStack(spacing: 10) {
                    CardView(card: card)
                        .scaleEffect(0.6)

                    if let exercise = gameManager.getExercise(for: card) {
                        VStack(spacing: 5) {
                            Text("\(card.exerciseCount) \(exercise.name)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)

                            Text(exercise.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }

                    Button("Complete") {
                        gameManager.completeCardForPlayer(player.id)
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.caption)
                }
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "rectangle.stack")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)

                    Button("Draw Card") {
                        gameManager.drawCardForPlayer(player.id)
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.subheadline)
                }
                .frame(height: 120)
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

struct CardView: View {
    let card: Card

    var body: some View {
        VStack {
            Text(card.displayText)
                .font(.system(size: 50))

            if !card.isJoker, let suit = card.suit {
                Text(suit.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 100, height: 120)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 3)
    }
}

struct PausedView: View {
    @ObservedObject var gameManager: GameManager

    var body: some View {
        VStack(spacing: 30) {
            Text("Game Paused")
                .font(.title)
                .fontWeight(.bold)

            HStack(spacing: 20) {
                Button("Resume") {
                    gameManager.resumeGame()
                }
                .buttonStyle(.borderedProminent)
                .font(.title2)

                Button("End Game") {
                    gameManager.endGame()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }
        }
    }
}

struct ExerciseSetupView: View {
    @ObservedObject var exerciseManager: ExerciseManager
    @Environment(\.dismiss) var dismiss
    @State private var showingExercisePicker = false
    @State private var selectedSuit: Suit?
    @State private var isSelectingForJoker = false
    @State private var showingNewExerciseSheet = false

    var body: some View {
        NavigationView {
            List {
                Section("Suit Exercises") {
                    ForEach(Suit.allCases, id: \.self) { suit in
                        HStack {
                            Text("\(suit.rawValue) \(suit.name)")
                                .font(.headline)

                            Spacer()

                            if let exercise = exerciseManager.suitExercises[suit] {
                                Text(exercise.name)
                                    .foregroundColor(.secondary)
                            }

                            Button("Change") {
                                selectedSuit = suit
                                isSelectingForJoker = false
                                showingExercisePicker = true
                            }
                            .buttonStyle(.bordered)
                            .font(.caption)
                        }
                    }
                }

                Section("Joker Exercise") {
                    HStack {
                        Text("🃏 Joker")
                            .font(.headline)

                        Spacer()

                        Text(exerciseManager.jokerExercise.name)
                            .foregroundColor(.secondary)

                        Button("Change") {
                            isSelectingForJoker = true
                            selectedSuit = nil
                            showingExercisePicker = true
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                    }
                }

                Section("Custom Exercises") {
                    ForEach(exerciseManager.customExercises) { exercise in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(exercise.name)
                                    .font(.headline)

                                Spacer()

                                Button("Delete") {
                                    exerciseManager.removeCustomExercise(exercise)
                                }
                                .foregroundColor(.red)
                                .font(.caption)
                            }

                            Text(exercise.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }

                    Button("Add New Exercise") {
                        showingNewExerciseSheet = true
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Exercise Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        exerciseManager.resetToDefaults()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView(
                    exerciseManager: exerciseManager,
                    selectedSuit: selectedSuit,
                    isSelectingForJoker: isSelectingForJoker
                )
            }
            .sheet(isPresented: $showingNewExerciseSheet) {
                NewExerciseView(exerciseManager: exerciseManager)
            }
        }
    }
}

struct ExercisePickerView: View {
    @ObservedObject var exerciseManager: ExerciseManager
    @Environment(\.dismiss) var dismiss
    let selectedSuit: Suit?
    let isSelectingForJoker: Bool

    var body: some View {
        NavigationView {
            List {
                Section("Default Exercises") {
                    ForEach(Exercise.defaultExercises) { exercise in
                        ExerciseRow(exercise: exercise) {
                            selectExercise(exercise)
                        }
                    }
                }

                if !exerciseManager.customExercises.isEmpty {
                    Section("Custom Exercises") {
                        ForEach(exerciseManager.customExercises) { exercise in
                            ExerciseRow(exercise: exercise) {
                                selectExercise(exercise)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Choose Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func selectExercise(_ exercise: Exercise) {
        if isSelectingForJoker {
            exerciseManager.setJokerExercise(exercise)
        } else if let suit = selectedSuit {
            exerciseManager.setExercise(for: suit, exercise: exercise)
        }
        dismiss()
    }
}

struct ExerciseRow: View {
    let exercise: Exercise
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(exercise.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }

                Text(exercise.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .padding(.vertical, 4)
        }
    }
}

struct NewExerciseView: View {
    @ObservedObject var exerciseManager: ExerciseManager
    @Environment(\.dismiss) var dismiss
    @State private var exerciseName = ""
    @State private var exerciseDescription = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Exercise Details")) {
                    TextField("Exercise Name", text: $exerciseName)
                    TextField("Description", text: $exerciseDescription)
                        .textFieldStyle(.roundedBorder)
                }

                Section {
                    Button("Add Exercise") {
                        if !exerciseName.isEmpty && !exerciseDescription.isEmpty {
                            exerciseManager.addCustomExercise(
                                name: exerciseName,
                                description: exerciseDescription
                            )
                            dismiss()
                        }
                    }
                    .disabled(exerciseName.isEmpty || exerciseDescription.isEmpty)
                }
            }
            .navigationTitle("New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}