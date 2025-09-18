import Foundation
import Combine

class GameManager: ObservableObject {
    @Published var deck = Deck()
    @Published var teamManager = TeamManager()
    @Published var timerManager = TimerManager()
    @Published var exerciseManager = ExerciseManager()

    @Published var currentCard: Card?
    @Published var gameState: GameState = .setup
    @Published var showingExerciseSetup = false

    enum GameState {
        case setup
        case playing
        case paused
        case cardDrawn
    }

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupObservers()
    }

    private func setupObservers() {
        timerManager.$timeRemaining
            .sink { [weak self] timeRemaining in
                if timeRemaining <= 0 && self?.gameState == .cardDrawn {
                    self?.completeCard()
                }
            }
            .store(in: &cancellables)
    }

    func startGame() {
        guard teamManager.hasPlayers else { return }
        gameState = .playing
        teamManager.reset()
        deck.reset()
    }

    func pauseGame() {
        gameState = .paused
        timerManager.pause()
    }

    func resumeGame() {
        gameState = .playing
        if currentCard != nil {
            timerManager.start()
        }
    }

    func endGame() {
        gameState = .setup
        timerManager.stop()
        currentCard = nil
    }

    func drawCard() {
        guard gameState == .playing else { return }

        if let card = deck.drawCard() {
            currentCard = card
            gameState = .cardDrawn
            timerManager.reset()
            timerManager.start()
        }
    }

    func completeCard() {
        guard gameState == .cardDrawn else { return }

        timerManager.stop()
        teamManager.nextPlayer()
        currentCard = nil
        gameState = .playing

        if deck.isExhausted {
            deck.reset()
        }
    }

    func skipCard() {
        completeCard()
    }

    var canDrawCard: Bool {
        return gameState == .playing && currentCard == nil
    }

    var currentExercise: Exercise? {
        guard let card = currentCard else { return nil }
        return exerciseManager.getExercise(for: card)
    }

    var exerciseCount: Int {
        return currentCard?.exerciseCount ?? 0
    }
}