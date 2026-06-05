import Foundation
import Combine

enum GamePhase {
    case compact
    case lobby
    case countdown(Int) // seconds remaining
    case racing
    case finished
}

@MainActor
final class GameState: ObservableObject {
    @Published var phase: GamePhase = .compact
    @Published var race: Race?
    @Published var localPlayerId: String
    @Published var localNickname: String
    @Published var typedText: String = ""
    @Published var wpm: Int = 0
    @Published var elapsedSeconds: TimeInterval = 0

    private lazy var raceService = RaceService.shared
    private var raceStartTime: Date?
    private var progressTimer: Timer?
    private var countdownTask: Task<Void, Never>?
    private var lastPushTime: Date = .distantPast

    init() {
        if let stored = UserDefaults(suiteName: "group.com.typeracer.shared")?.string(forKey: "playerId") {
            localPlayerId = stored
        } else {
            let newId = UUID().uuidString
            UserDefaults(suiteName: "group.com.typeracer.shared")?.set(newId, forKey: "playerId")
            localPlayerId = newId
        }
        localNickname = UserDefaults(suiteName: "group.com.typeracer.shared")?.string(forKey: "nickname") ?? "Player"
    }

    func saveNickname(_ name: String) {
        localNickname = name
        UserDefaults(suiteName: "group.com.typeracer.shared")?.set(name, forKey: "nickname")
    }

    // MARK: - Create Race

    func createRace() {
        let quote = QuoteService.shared.randomQuote(difficulty: .medium)
        let player = Player(id: localPlayerId, nickname: localNickname, isCreator: true)
        let newRace = raceService.createRace(
            sentence: quote.text,
            quoteAuthor: quote.author,
            quoteSource: quote.source,
            creator: player
        )
        race = newRace
        observeRace(id: newRace.id)
        phase = .lobby
    }

    // MARK: - Join Race

    func joinRace(raceId: String) {
        let player = Player(id: localPlayerId, nickname: localNickname)
        raceService.joinRace(raceId: raceId, player: player)
        observeRace(id: raceId)
        phase = .lobby
    }

    // MARK: - Start Countdown

    func startCountdown() {
        guard let raceId = race?.id else { return }
        countdownTask?.cancel()
        phase = .countdown(3)
        raceService.startCountdown(raceId: raceId)

        let capturedRaceId = raceId
        countdownTask = Task { [weak self] in
            for i in stride(from: 3, through: 1, by: -1) {
                if Task.isCancelled { return }
                await MainActor.run {
                    guard let self, !Task.isCancelled else { return }
                    self.phase = .countdown(i)
                }
                try? await Task.sleep(for: .seconds(1))
            }
            guard !Task.isCancelled else { return }
            await MainActor.run { [weak self] in
                guard let self, !Task.isCancelled else { return }
                self.raceService.startRacing(raceId: capturedRaceId)
            }
        }
    }

    // MARK: - Rematch

    func requestRematch() {
        guard let race, race.playerCount >= 2, race.status == .finished else { return }
        let quote = QuoteService.shared.randomQuote(difficulty: .medium)
        let raceId = race.id
        Task {
            try? await raceService.resetRaceForRematch(
                raceId: raceId,
                sentence: quote.text,
                quoteAuthor: quote.author,
                quoteSource: quote.source
            )
        }
    }

    // MARK: - Racing

    func beginRacing() {
        raceStartTime = Date()
        typedText = ""
        wpm = 0
        elapsedSeconds = 0
        phase = .racing

        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateElapsed()
            }
        }
    }

    private func updateElapsed() {
        guard let start = raceStartTime else { return }
        elapsedSeconds = Date().timeIntervalSince(start)
    }

    func onTypingChanged(_ text: String) {
        guard let sentence = race?.sentence else { return }
        typedText = text

        let correctChars = text.correctCharacterCount(against: sentence)
        let progress = text.typingProgress(against: sentence)
        wpm = String.wpm(correctChars: correctChars, elapsedSeconds: elapsedSeconds)

        // Throttle pushes to ~200ms
        let now = Date()
        if now.timeIntervalSince(lastPushTime) >= 0.2, let raceId = race?.id {
            lastPushTime = now
            raceService.updateProgress(raceId: raceId, playerId: localPlayerId, progress: progress, wpm: wpm)
        }

        if progress >= 1.0 {
            Task {
                await finishRace()
            }
        }
    }

    private func finishRace() async {
        progressTimer?.invalidate()
        progressTimer = nil

        guard let raceId = race?.id else { return }
        raceService.markPlayerFinished(raceId: raceId, playerId: localPlayerId, wpm: wpm)

        // Fetch fresh race state from Firebase to check if all players are done
        if let race = await raceService.fetchRace(raceId: raceId),
           race.players.values.allSatisfy({ $0.hasFinished }) {
            raceService.finishRace(raceId: raceId)
        }
    }

    // MARK: - Observe

    private func observeRace(id: String) {
        raceService.observeRace(raceId: id) { [weak self] updatedRace in
            Task { @MainActor in
                guard let self, let updatedRace else { return }
                self.race = updatedRace

                switch updatedRace.status {
                case .waiting:
                    switch self.phase {
                    case .finished, .racing, .countdown:
                        self.resetLocalForNewRound()
                        self.phase = .lobby
                    case .lobby, .compact:
                        break
                    }
                case .racing:
                    if case .racing = self.phase { } else {
                        self.beginRacing()
                    }
                case .finished:
                    self.progressTimer?.invalidate()
                    self.progressTimer = nil
                    self.phase = .finished
                case .countdown:
                    break
                }
            }
        }
    }

    private func resetLocalForNewRound() {
        countdownTask?.cancel()
        countdownTask = nil
        progressTimer?.invalidate()
        progressTimer = nil
        raceStartTime = nil
        typedText = ""
        wpm = 0
        elapsedSeconds = 0
        lastPushTime = .distantPast
    }

    // MARK: - Cleanup

    func cleanup() {
        countdownTask?.cancel()
        countdownTask = nil
        progressTimer?.invalidate()
        progressTimer = nil
        raceService.stopObserving()
    }

    deinit {
        progressTimer?.invalidate()
    }
}
