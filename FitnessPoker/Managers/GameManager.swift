import Foundation
import Combine
import SwiftUI

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
        // Forward changes from all child observable objects
        Publishers.MergeMany([
            deck.objectWillChange,
            teamManager.objectWillChange,
            timerManager.objectWillChange,
            exerciseManager.objectWillChange
        ])
        .sink { [weak self] _ in
            self?.objectWillChange.send()
        }
        .store(in: &cancellables)

        // Specific logic observers
        timerManager.$isExpired
            .sink { [weak self] isExpired in
                if isExpired && self?.gameState == .playing {
                    self?.endGame()
                }
            }
            .store(in: &cancellables)
    }

    func startGame() {
        print("GameManager.startGame() called")
        print("hasPlayers: \(teamManager.hasPlayers)")
        print("Current game state: \(gameState)")

        guard teamManager.hasPlayers else {
            print("No players found, exiting startGame")
            return
        }

        print("Starting game with \(teamManager.players.count) players")
        deck.reset()
        deck.shuffle()
        teamManager.reset()

        // Clear any existing cards from players
        for i in 0..<teamManager.players.count {
            teamManager.players[i].currentCard = nil
            teamManager.players[i].cardsDrawn = []
        }

        // Start timer if a limit is set
        if timerManager.timeLimit > 0 {
            timerManager.start()
        }

        // Change game state to trigger UI update
        gameState = .playing
        print("Game started successfully, state is now: \(gameState)")
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
        print("drawCardForPlayer called for player: \(playerId)")
        print("Current game state: \(gameState)")

        guard gameState == .playing else {
            print("Cannot draw card - game state is not playing")
            return
        }

        if let card = deck.drawCard() {
            print("Drew card: \(card.displayText)")
            teamManager.setCurrentCard(for: playerId, card: card)
            if deck.isExhausted {
                print("Deck exhausted, resetting...")
                deck.reset()
            }
        } else {
            print("Failed to draw card from deck")
        }
    }

    func getExercise(for card: Card) -> Exercise? {
        return exerciseManager.getExercise(for: card)
    }
}