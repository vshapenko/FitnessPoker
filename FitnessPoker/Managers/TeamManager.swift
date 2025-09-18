import Foundation

struct Player: Identifiable, Codable {
    let id = UUID()
    var name: String
    var isActive: Bool = true

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
        if currentPlayerIndex >= players.count {
            currentPlayerIndex = 0
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
}