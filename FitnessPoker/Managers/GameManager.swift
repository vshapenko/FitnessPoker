import Foundation
import Combine

class GameManager: ObservableObject {
    @Published var deck = Deck()
    @Published var teamManager = TeamManager()
    @Published var timerManager = TimerManager()
    @Published var exerciseManager = ExerciseManager()

    @Published var gameState: GameState = .setup
    @Published var showingExerciseSetup = false

    enum GameState {
        case setup
        case playing
        case paused
    }

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupObservers()
    }

    private func setupObservers() {
        timerManager.$isExpired
            .sink { [weak self] isExpired in
                if isExpired && self?.gameState == .playing {
                    self?.endGame()
                }
            }
            .store(in: &cancellables)
    }

    func startGame() {
        guard teamManager.hasPlayers else { return }
        gameState = .playing
        teamManager.reset()
        deck.reset()
        timerManager.start()
    }

    func pauseGame() {
        gameState = .paused
        timerManager.pause()
    }

    func resumeGame() {
        gameState = .playing
        timerManager.start()
    }

    func endGame() {
        gameState = .setup
        timerManager.stop()
        for i in 0..<teamManager.players.count {
            teamManager.players[i].currentCard = nil
        }
    }

    func drawCardForPlayer(_ playerId: UUID) {
        guard gameState == .playing else { return }

        if let card = deck.drawCard() {
            teamManager.setCurrentCard(for: playerId, card: card)
            if deck.isExhausted {
                deck.reset()
            }
        }
    }

    func completeCardForPlayer(_ playerId: UUID) {
        teamManager.setCurrentCard(for: playerId, card: nil)
    }

    func getExercise(for card: Card) -> Exercise? {
        return exerciseManager.getExercise(for: card)
    }
}