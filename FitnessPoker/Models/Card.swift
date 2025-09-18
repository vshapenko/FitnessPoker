import Foundation

enum Suit: String, CaseIterable, Codable {
    case hearts = "♥️"
    case diamonds = "♦️"
    case clubs = "♣️"
    case spades = "♠️"

    var name: String {
        switch self {
        case .hearts: return "Hearts"
        case .diamonds: return "Diamonds"
        case .clubs: return "Clubs"
        case .spades: return "Spades"
        }
    }
}

enum Rank: Int, CaseIterable, Codable {
    case two = 2, three, four, five, six, seven, eight, nine, ten
    case jack = 11, queen = 12, king = 13, ace = 14

    var symbol: String {
        switch self {
        case .two: return "2"
        case .three: return "3"
        case .four: return "4"
        case .five: return "5"
        case .six: return "6"
        case .seven: return "7"
        case .eight: return "8"
        case .nine: return "9"
        case .ten: return "10"
        case .jack: return "J"
        case .queen: return "Q"
        case .king: return "K"
        case .ace: return "A"
        }
    }

    var value: Int {
        switch self {
        case .jack, .queen, .king, .ace:
            return 10
        default:
            return self.rawValue
        }
    }
}

struct Card: Identifiable, Equatable, Codable {
    let id = UUID()
    let suit: Suit?
    let rank: Rank?
    let isJoker: Bool

    init(suit: Suit, rank: Rank) {
        self.suit = suit
        self.rank = rank
        self.isJoker = false
    }

    init(joker: Bool = true) {
        self.suit = nil
        self.rank = nil
        self.isJoker = joker
    }

    var displayText: String {
        if isJoker {
            return "🃏"
        }
        guard let suit = suit, let rank = rank else {
            return "?"
        }
        return "\(rank.symbol)\(suit.rawValue)"
    }

    var exerciseCount: Int {
        if isJoker {
            return 10
        }
        return rank?.value ?? 0
    }
}