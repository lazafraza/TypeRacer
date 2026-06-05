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
        players.values.sorted { a, b in
            switch (a.hasFinished, b.hasFinished) {
            case (true, true):
                if a.wpm != b.wpm {
                    return a.wpm > b.wpm
                }
                return (a.finishedAt ?? .infinity) < (b.finishedAt ?? .infinity)
            case (true, false):
                return true
            case (false, true):
                return false
            case (false, false):
                return a.progress > b.progress
            }
        }
    }

    /// Finishers ranked for results: highest WPM first; ties broken by earlier `finishedAt`; then DNFs by progress.
    var playersRankedForResults: [Player] {
        players.values.sorted(by: Self.resultsDisplayOrder)
    }

    /// Highest WPM among finishers; ties broken by earlier `finishedAt`.
    var winner: Player? {
        playersRankedForResults.first(where: \.hasFinished)
    }

    var playerCount: Int { players.count }

    private static func resultsDisplayOrder(lhs: Player, rhs: Player) -> Bool {
        switch (lhs.hasFinished, rhs.hasFinished) {
        case (true, true):
            if lhs.wpm != rhs.wpm { return lhs.wpm > rhs.wpm }
            return (lhs.finishedAt ?? .infinity) < (rhs.finishedAt ?? .infinity)
        case (true, false):
            return true
        case (false, true):
            return false
        default:
            return lhs.progress > rhs.progress
        }
    }
}
