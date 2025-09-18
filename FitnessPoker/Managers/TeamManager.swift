import Foundation
import SwiftUI

struct Player: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var isActive: Bool = true
    var currentCard: Card?
    var cardsDrawn: [Card] = []
    var cardProcessingTimes: [TimeInterval] = []
    var currentCardDrawTime: Date?

    init(name: String) {
        self.name = name
    }
}

class TeamManager: ObservableObject {
    @Published var players: [Player] = []

    private let maxPlayers = 4

    func addPlayer(_ name: String) -> Bool {
        guard players.count < maxPlayers else { return false }
        let player = Player(name: name)
        print("Adding player: \(player.name) with ID: \(player.id)")
        players.append(player)
        print("Players array now has \(players.count) players")
        return true
    }

    func removePlayer(at index: Int) {
        print("removePlayer(at:) called with index: \(index)")
        print("Current players count: \(players.count)")
        guard index < players.count else {
            print("Index \(index) out of bounds")
            return
        }
        let playerName = players[index].name
        players.remove(at: index)
        print("Removed player: \(playerName), remaining count: \(players.count)")
    }

    func removePlayer(withId id: UUID) {
        print("Attempting to remove player with ID: \(id)")
        print("Current players: \(players.map { "\($0.name) (\($0.id))" }.joined(separator: ", "))")

        if let index = players.firstIndex(where: { $0.id == id }) {
            let playerName = players[index].name
            print("Found player at index \(index): \(playerName)")

            // Remove the player
            players.remove(at: index)

            print("Removed player: \(playerName)")
        } else {
            print("Player with ID \(id) not found")
        }

        print("Players after removal: \(players.count)")
    }

    var canAddPlayer: Bool {
        return players.count < maxPlayers
    }

    var hasPlayers: Bool {
        return !players.isEmpty
    }

    func reset() {
        // This function used to reset currentPlayerIndex, now it does nothing.
        // It can be expanded later if player state needs resetting.
    }

    func setPlayerActive(_ player: Player, isActive: Bool) {
        if let index = players.firstIndex(where: { $0.id == player.id }) {
            var updatedPlayer = players[index]
            updatedPlayer.isActive = isActive
            players[index] = updatedPlayer
        }
    }

    func setCurrentCard(for playerId: UUID, card: Card?) {
        print("setCurrentCard called for player: \(playerId), card: \(card?.displayText ?? "nil")")
        if let index = players.firstIndex(where: { $0.id == playerId }) {
            print("Found player at index: \(index)")

            // Create a modified copy of the player
            var updatedPlayer = players[index]
            updatedPlayer.currentCard = card
            if let card = card {
                updatedPlayer.cardsDrawn.append(card)
            }

            // Replace the entire array element to trigger SwiftUI update
            players[index] = updatedPlayer
            print("Card set successfully, UI should update")
        } else {
            print("Player not found with ID: \(playerId)")
        }
    }
}