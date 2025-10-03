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
                case .finished:
                    GameFinishedView(gameManager: gameManager)
                }
            }
            .padding()
            .navigationTitle("Fitness Poker")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct GameFinishedView: View {
    @ObservedObject var gameManager: GameManager
    @State private var selectedPlayer: Player? // For presenting the detail sheet

    var body: some View {
        VStack(spacing: 20) {
            Text("Game Over!")
                .font(.largeTitle)
                .fontWeight(.bold)

            List(gameManager.teamManager.players) { player in
                Button(action: { self.selectedPlayer = player }) {
                    HStack {
                        Text(player.name)
                            .font(.headline)
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Cards: \(player.cardsDrawn.count)")
                            Text("Avg: \(averageTime(for: player))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Image(systemName: "chevron.right").padding(.leading, 5)
                    }
                    .foregroundColor(.primary)
                }
            }

            Button("Play Again") {
                gameManager.resetGame()
            }
            .buttonStyle(.borderedProminent)
            .font(.title2)
            .padding()
        }
        .sheet(item: $selectedPlayer) { player in
            PlayerStatsDetailView(player: player, gameManager: gameManager)
        }
    }

    private func averageTime(for player: Player) -> String {
        if player.cardProcessingTimes.isEmpty {
            return "N/A"
        }
        let totalTime = player.cardProcessingTimes.reduce(0, +)
        let average = totalTime / Double(player.cardProcessingTimes.count)
        return String(format: "%.1fs", average)
    }
}

struct PlayerStatsDetailView: View {
    let player: Player
    @ObservedObject var gameManager: GameManager // Pass gameManager to get exercise info

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Overall Stats")) {
                    HStack {
                        Text("Total Cards Drawn")
                        Spacer()
                        Text("\(player.cardsDrawn.count)")
                    }
                    HStack {
                        Text("Average Time / Card")
                        Spacer()
                        Text(averageTime)
                    }
                }

                Section(header: Text("Time per Card")) {
                    if player.cardProcessingTimes.isEmpty {
                        Text("No cards were completed.")
                    } else {
                        // We zip the times with the cards that *were* completed
                        ForEach(Array(zip(player.cardsDrawn, player.cardProcessingTimes).enumerated()), id: \.offset) { index, element in
                            let (card, time) = element
                            HStack {
                                if let exercise = gameManager.getExercise(for: card) {
                                    Text("\(index + 1). \(card.displayText): \(gameManager.getExerciseCount(for: card)) \(exercise.name)")
                                } else {
                                    Text("\(index + 1). \(card.displayText): No exercise assigned")
                                }
                                Spacer()
                                Text(String(format: "%.1fs", time))
                            }
                        }
                    }
                }
            }
            .navigationTitle("\(player.name)'s Stats")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var averageTime: String {
        if player.cardProcessingTimes.isEmpty {
            return "N/A"
        }
        let totalTime = player.cardProcessingTimes.reduce(0, +)
        let average = totalTime / Double(player.cardProcessingTimes.count)
        return String(format: "%.1fs", average)
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
        GeometryReader { geometry in
            VStack(spacing: 10) {
                Text("Players")
                    .font(.title3)
                    .fontWeight(.semibold)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                    ForEach(gameManager.teamManager.players, id: \.id) { player in
                        PlayerGameCard(
                            player: player,
                            gameManager: gameManager,
                            availableHeight: calculateCardHeight(for: geometry.size, playerCount: gameManager.teamManager.players.count)
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
            }
        }
    }

    private func calculateCardHeight(for size: CGSize, playerCount: Int) -> CGFloat {
        let titleHeight: CGFloat = 30
        let buttonHeight: CGFloat = 50
        let spacing: CGFloat = 10
        let gridSpacing: CGFloat = 12

        let availableHeight = size.height - titleHeight - buttonHeight - (spacing * 2)

        // Calculate rows (2 columns max, so divide by 2 rounded up)
        let rows = ceil(Double(playerCount) / 2.0)
        let totalSpacing = gridSpacing * (rows - 1)

        return (availableHeight - totalSpacing) / CGFloat(rows)
    }
}

struct PlayerGameCard: View {
    let player: Player
    @ObservedObject var gameManager: GameManager
    let availableHeight: CGFloat

    var body: some View {
        ZStack(alignment: .top) {
            if let card = player.currentCard {
                CardView(
                    card: card,
                    exercise: gameManager.getExercise(for: card),
                    exerciseCount: gameManager.getExerciseCount(for: card),
                    playerName: player.name,
                    cardsDrawn: player.cardsDrawn.count
                )
            } else {
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
                    .padding(.horizontal, 12)
                    .padding(.top, 12)

                    Spacer()

                    Image(systemName: "rectangle.stack")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("Tap to Draw")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(15)
            }
        }
        .frame(height: availableHeight)
        .contentShape(Rectangle())
        .onTapGesture {
            gameManager.drawCardForPlayer(player.id)
        }
    }
}

struct CardView: View {
    let card: Card
    var exercise: Exercise? = nil
    var exerciseCount: Int? = nil
    var playerName: String? = nil
    var cardsDrawn: Int? = nil

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Card background
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white)
                    .shadow(radius: 3)

                VStack(spacing: 0) {
                    // Header with player info
                    if let name = playerName, let count = cardsDrawn {
                        HStack {
                            Text(name)
                                .font(.headline)
                                .fontWeight(.semibold)

                            Spacer()

                            Text("Cards: \(count)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                    }

                    Spacer()

                    // Card content
                    VStack(spacing: 5) {
                        Text(card.displayText)
                            .font(.system(size: min(geometry.size.width * 0.4, geometry.size.height * 0.3)))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)

                        if let exercise = exercise, let count = exerciseCount {
                            Text("\(count) \(exercise.name)")
                                .font(.system(size: min(geometry.size.width * 0.11, geometry.size.height * 0.11)))
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.7)
                                .padding(.horizontal, 8)
                                .padding(.top, 4)
                        }
                    }

                    Spacer()
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

// Helper extension for rounded corners on specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
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
    @State private var selectedJokerId: String?
    @State private var showingNewExerciseSheet = false
    private let jokerIds = ["Joker 1", "Joker 2"]

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
                                        selectedJokerId = nil
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
                        Text("Joker Exercises")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(spacing: 8) {
                            ForEach(jokerIds, id: \.self) { jokerId in
                                VStack(spacing: 4) {
                                    HStack {
                                        Text("🃏 \(jokerId)")
                                            .font(.subheadline)
                                            .fontWeight(.medium)

                                        Spacer()

                                        if let exercise = exerciseManager.jokerExercises[jokerId] {
                                            VStack(alignment: .trailing, spacing: 2) {
                                                Text(exercise.name)
                                                    .foregroundColor(.secondary)
                                                    .font(.caption)
                                                Text("\(exerciseManager.getJokerRepetitions(for: jokerId)) reps")
                                                    .foregroundColor(.secondary)
                                                    .font(.caption2)
                                            }
                                        }

                                        Button("Change") {
                                            selectedJokerId = jokerId
                                            selectedSuit = nil
                                            showingExercisePicker = true
                                        }
                                        .buttonStyle(.bordered)
                                        .font(.caption)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
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
                    selectedJokerId: selectedJokerId
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
    let selectedJokerId: String?
    @State private var selectedExercise: Exercise?
    @State private var repetitions: String = ""
    @State private var showingRepetitionInput = false

    var body: some View {
        NavigationView {
            ZStack {
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

                if showingRepetitionInput, selectedJokerId != nil {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                showingRepetitionInput = false
                            }

                        VStack(spacing: 15) {
                            Text("Set Repetitions")
                                .font(.headline)

                            TextField("Repetitions", text: $repetitions)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                                .frame(width: 150)
                                .multilineTextAlignment(.center)

                            HStack(spacing: 15) {
                                Button("Cancel") {
                                    showingRepetitionInput = false
                                }
                                .buttonStyle(.bordered)

                                Button("Confirm") {
                                    confirmSelection()
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(repetitions.isEmpty)
                            }
                        }
                        .padding(25)
                        .background(Color(.systemBackground))
                        .cornerRadius(15)
                        .shadow(radius: 10)
                        .frame(maxWidth: 300)
                    }
                }
            }
            .navigationTitle(selectedJokerId != nil ? "Choose Exercise & Reps" : "Choose Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let jokerId = selectedJokerId {
                    repetitions = String(exerciseManager.getJokerRepetitions(for: jokerId))
                }
            }
        }
    }

    private func selectExercise(_ exercise: Exercise) {
        if selectedJokerId != nil {
            selectedExercise = exercise
            showingRepetitionInput = true
        } else if let suit = selectedSuit {
            exerciseManager.setExercise(for: suit, exercise: exercise)
            dismiss()
        }
    }

    private func confirmSelection() {
        guard let exercise = selectedExercise, let jokerId = selectedJokerId else { return }
        let reps = Int(repetitions) ?? 20
        exerciseManager.setJokerExercise(for: jokerId, exercise: exercise, repetitions: reps)
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