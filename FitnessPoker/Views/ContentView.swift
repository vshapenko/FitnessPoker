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
    @FocusState private var isPlayerNameFieldFocused: Bool
    @State private var showingExerciseSetup = false

    var body: some View {
        VStack(spacing: 20) {
            // Exercise Setup Button
            Button(action: {
                showingExerciseSetup = true
            }) {
                HStack {
                    Image(systemName: "dumbbell.fill")
                    Text("Setup Exercises")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }

            Text("Add Players (Max 4)")
                .font(.title2)
                .fontWeight(.semibold)

            HStack {
                TextField("Player name", text: $newPlayerName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isPlayerNameFieldFocused)
                    .onSubmit {
                        addPlayer()
                    }

                Button("Add") {
                    addPlayer()
                }
                .buttonStyle(.borderedProminent)
                .disabled(newPlayerName.isEmpty || !gameManager.teamManager.canAddPlayer)
            }

            if !gameManager.teamManager.players.isEmpty {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 10) {
                        ForEach(gameManager.teamManager.players, id: \.id) { player in
                            PlayerCard(player: player) {
                                gameManager.teamManager.removePlayer(withId: player.id)
                            }
                        }
                    }
                }
                .frame(maxHeight: 200)
                .animation(.default, value: gameManager.teamManager.players.count)
            }

            TimerSetupView(timerManager: gameManager.timerManager)

            Button("Start Game") {
                gameManager.startGame()
            }
            .buttonStyle(.borderedProminent)
            .font(.title2)
            .padding()
            .disabled(!gameManager.teamManager.hasPlayers)
        }
        .sheet(isPresented: $showingExerciseSetup) {
            ExerciseSetupView(exerciseManager: gameManager.exerciseManager)
        }
    }

    private func addPlayer() {
        guard !newPlayerName.isEmpty else { return }
        if gameManager.teamManager.addPlayer(newPlayerName) {
            newPlayerName = ""
            isPlayerNameFieldFocused = true
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
                .foregroundColor(.primary)

            Spacer()

            Button(action: {
                onRemove()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .imageScale(.medium)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemBlue).opacity(0.1))
        .cornerRadius(8)
    }
}

struct TimerSetupView: View {
    @ObservedObject var timerManager: TimerManager
    @State private var showingCustomTime = false
    @State private var customMinutes: String = ""
    @State private var customSeconds: String = ""
    @FocusState private var isCustomTimeFocused: Bool

    var body: some View {
        VStack(spacing: 10) {
            Text("Game Time Limit")
                .font(.headline)

            HStack(spacing: 10) {
                TimerButton(title: "No Limit", seconds: 0, timerManager: timerManager)
                TimerButton(title: "5m", seconds: 300, timerManager: timerManager)
                TimerButton(title: "10m", seconds: 600, timerManager: timerManager)
                TimerButton(title: "15m", seconds: 900, timerManager: timerManager)
            }

            Button(action: {
                showingCustomTime.toggle()
                if showingCustomTime {
                    isCustomTimeFocused = true
                }
            }) {
                Text("Custom")
                    .font(.subheadline)
                    .foregroundColor(showingCustomTime ? .white : .primary)
            }
            .buttonStyle(.bordered)
            .background(showingCustomTime ? Color.blue : Color.clear)
            .cornerRadius(8)

            if showingCustomTime {
                HStack {
                    TextField("Min", text: $customMinutes)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 60)
                        .keyboardType(.numberPad)
                        .focused($isCustomTimeFocused)

                    Text(":")

                    TextField("Sec", text: $customSeconds)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 60)
                        .keyboardType(.numberPad)

                    Button("Set") {
                        let minutes = Int(customMinutes) ?? 0
                        let seconds = Int(customSeconds) ?? 0
                        let totalSeconds = TimeInterval(minutes * 60 + seconds)
                        if totalSeconds > 0 {
                            timerManager.setTimeLimit(totalSeconds)
                            showingCustomTime = false
                            customMinutes = ""
                            customSeconds = ""
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(customMinutes.isEmpty && customSeconds.isEmpty)
                }
                .padding(.top, 5)
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
                ForEach(gameManager.teamManager.players, id: \.id) { player in
                    PlayerGameCard(player: player, gameManager: gameManager)
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

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(player.name)
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Text("Cards: \(player.cardsDrawn.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            VStack {
                if let card = player.currentCard {
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
                        .padding(.horizontal, 4)
                    }
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "rectangle.stack")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("Tap to Draw")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 150)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
        .contentShape(Rectangle()) // Makes the whole area tappable, including blank space
        .onTapGesture {
            gameManager.drawCardForPlayer(player.id)
        }
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
            ScrollView {
                VStack(spacing: 20) {
                    // Suit Exercises Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Suit Exercises")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(spacing: 8) {
                            ForEach(Suit.allCases, id: \.self) { suit in
                                HStack {
                                    Text("\(suit.rawValue) \(suit.name)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)

                                    Spacer()

                                    if let exercise = exerciseManager.suitExercises[suit] {
                                        Text(exercise.name)
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                    }

                                    Button("Change") {
                                        selectedSuit = suit
                                        isSelectingForJoker = false
                                        showingExercisePicker = true
                                    }
                                    .buttonStyle(.bordered)
                                    .font(.caption)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Joker Exercise Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Joker Exercise")
                            .font(.headline)
                            .padding(.horizontal)

                        HStack {
                            Text("🃏 Joker")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Spacer()

                            Text(exerciseManager.jokerExercise.name)
                                .foregroundColor(.secondary)
                                .font(.caption)

                            Button("Change") {
                                isSelectingForJoker = true
                                selectedSuit = nil
                                showingExercisePicker = true
                            }
                            .buttonStyle(.bordered)
                            .font(.caption)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }

                    // Custom Exercises Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Custom Exercises")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(spacing: 8) {
                            ForEach(exerciseManager.customExercises) { exercise in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(exercise.name)
                                            .font(.subheadline)
                                            .fontWeight(.medium)

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
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }

                            Button("Add New Exercise") {
                                showingNewExerciseSheet = true
                            }
                            .foregroundColor(.blue)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 50)
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