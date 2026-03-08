import Foundation

struct Player: Codable, Identifiable {
    let id: String
    var nickname: String
    var progress: Double      // 0.0 to 1.0
    var wpm: Int
    var finishedAt: Double?
    var isCreator: Bool

    init(id: String = UUID().uuidString,
         nickname: String,
         progress: Double = 0,
         wpm: Int = 0,
         finishedAt: Double? = nil,
         isCreator: Bool = false) {
        self.id = id
        self.nickname = nickname
        self.progress = progress
        self.wpm = wpm
        self.finishedAt = finishedAt
        self.isCreator = isCreator
    }

    var hasFinished: Bool { finishedAt != nil }
}
