import Foundation

struct Player: Identifiable {
    let id = UUID()
    var name: String
    var isActive: Bool = true
    var currentCard: Card?
    var cardsDrawn: [Card] = []

    init(name: String) {
        self.name = name
    }
}

class TeamManager: ObservableObject {
    @Published var players: [Player] = []
    @Published var currentPlayerIndex: Int = 0

    private let maxPlayers = 4

    func addPlayer(_ name: String) -> Bool {
        guard players.count < maxPlayers else { return false }
        let player = Player(name: name)
        players.append(player)
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
        if currentPlayerIndex >= players.count && !players.isEmpty {
            currentPlayerIndex = players.count - 1
        } else if players.isEmpty {
            currentPlayerIndex = 0
        }
    }

    func removePlayer(withId id: UUID) {
        print("removePlayer(withId:) called with id: \(id)")
        if let index = players.firstIndex(where: { $0.id == id }) {
            print("Found player at index: \(index)")
            removePlayer(at: index)
        } else {
            print("Player with id \(id) not found")
        }
    }

    func nextPlayer() {
        guard !players.isEmpty else { return }
        currentPlayerIndex = (currentPlayerIndex + 1) % players.count
    }

    var currentPlayer: Player? {
        guard !players.isEmpty && currentPlayerIndex < players.count else { return nil }
        return players[currentPlayerIndex]
    }

    var canAddPlayer: Bool {
        return players.count < maxPlayers
    }

    var hasPlayers: Bool {
        return !players.isEmpty
    }

    func reset() {
        currentPlayerIndex = 0
    }

    func setPlayerActive(_ player: Player, isActive: Bool) {
        if let index = players.firstIndex(where: { $0.id == player.id }) {
            players[index].isActive = isActive
        }
    }

    func setCurrentCard(for playerId: UUID, card: Card?) {
        if let index = players.firstIndex(where: { $0.id == playerId }) {
            players[index].currentCard = card
            if let card = card {
                players[index].cardsDrawn.append(card)
            }
        }
    }

    func selectPlayer(_ playerId: UUID) {
        if let index = players.firstIndex(where: { $0.id == playerId }) {
            currentPlayerIndex = index
        }
    }
}