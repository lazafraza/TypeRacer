import Foundation

enum QuoteDifficulty: String, Codable, CaseIterable {
    case short
    case medium
    case long
}

struct Quote: Codable, Identifiable {
    let id: Int
    let text: String
    let source: String
    let author: String
    let difficulty: QuoteDifficulty
}

final class QuoteService {
    static let shared = QuoteService()

    private let quotes: [Quote]

    private init() {
        guard let url = Bundle.main.url(forResource: "quotes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Quote].self, from: data) else {
            quotes = []
            return
        }
        quotes = decoded
    }

    func randomQuote(difficulty: QuoteDifficulty? = nil) -> Quote {
        let pool: [Quote]
        if let difficulty {
            pool = quotes.filter { $0.difficulty == difficulty }
        } else {
            pool = quotes
        }
        return pool.randomElement() ?? Quote(
            id: 0,
            text: "The quick brown fox jumps over the lazy dog.",
            source: "Fallback",
            author: "Unknown",
            difficulty: .short
        )
    }

    func quote(byId id: Int) -> Quote? {
        quotes.first { $0.id == id }
    }
}
