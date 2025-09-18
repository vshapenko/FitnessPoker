import Foundation

class Deck: ObservableObject {
    @Published private(set) var cards: [Card] = []
    @Published private(set) var drawnCards: [Card] = []

    init() {
        reset()
    }

    func reset() {
        cards = createFullDeck()
        drawnCards = []
        shuffle()
    }

    private func createFullDeck() -> [Card] {
        var deck: [Card] = []

        for suit in Suit.allCases {
            for rank in Rank.allCases {
                deck.append(Card(suit: suit, rank: rank))
            }
        }

        deck.append(Card(joker: true))
        deck.append(Card(joker: true))

        return deck
    }

    func shuffle() {
        cards.shuffle()
    }

    func drawCard() -> Card? {
        if cards.isEmpty {
            reset()
        }

        guard !cards.isEmpty else { return nil }

        let card = cards.removeFirst()
        drawnCards.append(card)
        return card
    }

    var remainingCount: Int {
        return cards.count
    }

    var totalCards: Int {
        return 54
    }

    var isExhausted: Bool {
        return cards.isEmpty
    }
}