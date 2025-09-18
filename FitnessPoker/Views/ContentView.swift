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
                case .cardDrawn:
                    CardDrawnView(gameManager: gameManager)
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

                if let currentPlayer = gameManager.teamManager.currentPlayer {
                    VStack(alignment: .trailing) {
                        Text("Current Player")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(currentPlayer.name)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
            }

            if gameManager.gameState == .cardDrawn {
                HStack {
                    Text("Time: \(gameManager.timerManager.formattedTime)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(gameManager.timerManager.timeRemaining < 10 ? .red : .primary)

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
                ForEach(Array(gameManager.teamManager.players.enumerated()), id: \.element.id) { index, player in
                    PlayerCard(player: player) {
                        gameManager.teamManager.removePlayer(at: index)
                    }
                }
            }

            TimerSetupView(timerManager: gameManager.timerManager)

            Button("Start Game") {
                gameManager.startGame()
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
            Text("Exercise Time Limit")
                .font(.headline)

            HStack {
                Button("30s") {
                    timerManager.setTimeLimit(30)
                }
                .buttonStyle(.bordered)

                Button("60s") {
                    timerManager.setTimeLimit(60)
                }
                .buttonStyle(.bordered)

                Button("90s") {
                    timerManager.setTimeLimit(90)
                }
                .buttonStyle(.bordered)

                Button("2m") {
                    timerManager.setTimeLimit(120)
                }
                .buttonStyle(.bordered)
            }

            Text("Selected: \(Int(timerManager.timeLimit))s")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct PlayingView: View {
    @ObservedObject var gameManager: GameManager

    var body: some View {
        VStack(spacing: 30) {
            Text("Ready to draw a card?")
                .font(.title)
                .multilineTextAlignment(.center)

            Button(action: {
                gameManager.drawCard()
            }) {
                VStack {
                    Image(systemName: "rectangle.stack.fill")
                        .font(.system(size: 60))
                    Text("Draw Card")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .frame(width: 200, height: 150)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(15)
            }
            .disabled(!gameManager.canDrawCard)

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

struct CardDrawnView: View {
    @ObservedObject var gameManager: GameManager

    var body: some View {
        VStack(spacing: 30) {
            if let card = gameManager.currentCard {
                CardView(card: card)

                if let exercise = gameManager.currentExercise {
                    VStack(spacing: 15) {
                        Text("\(gameManager.exerciseCount) \(exercise.name)")
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text(exercise.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }

            HStack(spacing: 20) {
                Button("Complete") {
                    gameManager.completeCard()
                }
                .buttonStyle(.borderedProminent)
                .font(.title2)

                Button("Skip") {
                    gameManager.skipCard()
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

struct CardView: View {
    let card: Card

    var body: some View {
        VStack {
            Text(card.displayText)
                .font(.system(size: 80))

            if !card.isJoker, let suit = card.suit {
                Text(suit.name)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 150, height: 200)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
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
    @Environment(\.presentationMode) var presentationMode

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
                    }
                }
            }
            .navigationTitle("Exercise Setup")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Reset") {
                    exerciseManager.resetToDefaults()
                },
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

#Preview {
    ContentView()
}