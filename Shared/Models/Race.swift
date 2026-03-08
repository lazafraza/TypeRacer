import Foundation

enum RaceStatus: String, Codable {
    case waiting
    case countdown
    case racing
    case finished
}

struct Race: Codable, Identifiable {
    let id: String
    var sentence: String
    var quoteAuthor: String
    var quoteSource: String
    var status: RaceStatus
    var players: [String: Player]
    var createdAt: Double
    var countdownStartAt: Double?
    var raceStartAt: Double?

    init(id: String = UUID().uuidString,
         sentence: String,
         quoteAuthor: String = "",
         quoteSource: String = "",
         status: RaceStatus = .waiting,
         players: [String: Player] = [:],
         createdAt: Double = Date().timeIntervalSince1970) {
        self.id = id
        self.sentence = sentence
        self.quoteAuthor = quoteAuthor
        self.quoteSource = quoteSource
        self.status = status
        self.players = players
        self.createdAt = createdAt
    }

    var sortedPlayers: [Player] {
        players.values.sorted { ($0.progress, $0.wpm) > ($1.progress, $1.wpm) }
    }

    var winner: Player? {
        players.values
            .filter { $0.finishedAt != nil }
            .min { ($0.finishedAt ?? .infinity) < ($1.finishedAt ?? .infinity) }
    }

    var playerCount: Int { players.count }
}
