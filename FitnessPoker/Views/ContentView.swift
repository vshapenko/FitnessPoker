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
                        gameManager.teamManager.removePlayer(withId: player.id)
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
            Text("Game Time Limit")
                .font(.headline)

            HStack {
                Button("No Limit") {
                    timerManager.setTimeLimit(0)
                }
                .buttonStyle(.bordered)

                Button("5m") {
                    timerManager.setTimeLimit(300)
                }
                .buttonStyle(.bordered)

                Button("10m") {
                    timerManager.setTimeLimit(600)
                }
                .buttonStyle(.bordered)

                Button("15m") {
                    timerManager.setTimeLimit(900)
                }
                .buttonStyle(.bordered)
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