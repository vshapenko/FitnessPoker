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
        guard index < players.count else { return }
        players.remove(at: index)
        if currentPlayerIndex >= players.count && !players.isEmpty {
            currentPlayerIndex = players.count - 1
        } else if players.isEmpty {
            currentPlayerIndex = 0
        }
    }

    func removePlayer(withId id: UUID) {
        if let index = players.firstIndex(where: { $0.id == id }) {
            removePlayer(at: index)
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