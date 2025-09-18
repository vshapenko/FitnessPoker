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
        case finished
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
        guard teamManager.hasPlayers else { return }

        deck.reset()
        deck.shuffle()
        teamManager.reset()

        // Reset player stats and cards for a new game
        for i in 0..<teamManager.players.count {
            teamManager.players[i].currentCard = nil
            teamManager.players[i].cardsDrawn = []
            teamManager.players[i].cardProcessingTimes = []
            teamManager.players[i].currentCardDrawTime = nil
        }

        if timerManager.timeLimit > 0 {
            timerManager.start()
        }

        gameState = .playing
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
        timerManager.stop()

        // Finalize stats for any player with an active card
        for i in 0..<teamManager.players.count {
            if let drawTime = teamManager.players[i].currentCardDrawTime {
                let timeSpent = Date().timeIntervalSince(drawTime)
                teamManager.players[i].cardProcessingTimes.append(timeSpent)
                teamManager.players[i].currentCardDrawTime = nil // Clear the time to prevent re-counting
            }
        }

        gameState = .finished
    }

    func resetGame() {
        deck.reset()
        teamManager.players = []
        timerManager.reset()
        gameState = .setup
    }

    func drawCardForPlayer(_ playerId: UUID) {
        guard gameState == .playing else { return }

        // Find the player and update their stats for the previous card
        if let playerIndex = teamManager.players.firstIndex(where: { $0.id == playerId }) {
            if let drawTime = teamManager.players[playerIndex].currentCardDrawTime {
                let timeSpent = Date().timeIntervalSince(drawTime)
                teamManager.players[playerIndex].cardProcessingTimes.append(timeSpent)
            }
        }

        // Draw the new card
        if let card = deck.drawCard() {
            teamManager.setCurrentCard(for: playerId, card: card)
            // After setting the new card, also set its draw time
            if let playerIndex = teamManager.players.firstIndex(where: { $0.id == playerId }) {
                teamManager.players[playerIndex].currentCardDrawTime = Date()
            }

            if deck.isExhausted {
                deck.reset()
            }
        } else {
            // Handle case where deck is empty and cannot draw
        }
    }

    func getExercise(for card: Card) -> Exercise? {
        return exerciseManager.getExercise(for: card)
    }
}