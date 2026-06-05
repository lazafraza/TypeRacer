import Foundation
import Combine
import FirebaseAuth

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
    @Published var isConnected: Bool = true
    @Published var actionError: String?

    private lazy var raceService = RaceService.shared
    private var raceStartTime: Date?
    private var progressTimer: Timer?
    private var countdownTask: Task<Void, Never>?
    private var lastPushTime: Date = .distantPast
    private var localPlayerFinished = false

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

        if let raceId = race?.id {
            raceService.updatePlayerNickname(raceId: raceId, playerId: localPlayerId, nickname: name)
        }
    }

    func clearActionError() {
        actionError = nil
    }

    // MARK: - Create Race

    func createRace(completion: ((Bool) -> Void)? = nil) {
        ensureAuthenticated { [weak self] ok in
            guard let self, ok else {
                completion?(false)
                return
            }
            let quote = QuoteService.shared.randomQuote(difficulty: .medium)
            let player = Player(id: self.localPlayerId, nickname: self.localNickname, isCreator: true)
            let newRace = self.raceService.createRace(
                sentence: quote.text,
                quoteAuthor: quote.author,
                quoteSource: quote.source,
                creator: player
            )
            self.race = newRace
            self.observeRace(id: newRace.id)
            self.phase = .lobby
            completion?(true)
        }
    }

    // MARK: - Load Race (spectate / results — no player write)

    func loadRace(raceId: String, initialPhase: GamePhase? = nil, completion: ((Bool) -> Void)? = nil) {
        ensureAuthenticated { [weak self] ok in
            guard let self, ok else {
                completion?(false)
                return
            }
            self.observeRace(id: raceId)
            if let initialPhase {
                self.phase = initialPhase
            }
            completion?(true)
        }
    }

    // MARK: - Join Race

    func joinRace(raceId: String, completion: ((Bool) -> Void)? = nil) {
        ensureAuthenticated { [weak self] ok in
            guard let self, ok else {
                completion?(false)
                return
            }
            let player = Player(id: self.localPlayerId, nickname: self.localNickname)
            self.raceService.joinRace(raceId: raceId, player: player)
            self.observeRace(id: raceId)
            self.phase = .lobby
            completion?(true)
        }
    }

    // MARK: - Start Countdown

    func startCountdown() {
        guard case .lobby = phase, let raceId = race?.id else { return }
        countdownTask?.cancel()
        phase = .countdown(3)
        raceService.startCountdown(raceId: raceId)
        runCountdownAnimation(raceId: raceId, shouldStartRacing: true)
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
        localPlayerFinished = false
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
        guard !localPlayerFinished, let sentence = race?.sentence else { return }
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
        localPlayerFinished = true
        progressTimer?.invalidate()
        progressTimer = nil

        guard let raceId = race?.id else { return }
        raceService.markPlayerFinished(raceId: raceId, playerId: localPlayerId, wpm: wpm)

        if let race = await raceService.fetchRace(raceId: raceId),
           race.players.values.allSatisfy({ $0.hasFinished }) {
            raceService.finishRace(raceId: raceId)
        }
    }

    // MARK: - Observe

    private func observeRace(id: String) {
        raceService.startMonitoringConnection { [weak self] connected in
            Task { @MainActor in
                self?.isConnected = connected
            }
        }

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
                case .countdown:
                    if case .lobby = self.phase {
                        self.runCountdownAnimation(raceId: updatedRace.id, shouldStartRacing: false)
                    }
                case .racing:
                    if case .racing = self.phase { } else {
                        self.beginRacing()
                    }
                case .finished:
                    self.progressTimer?.invalidate()
                    self.progressTimer = nil
                    self.phase = .finished
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
        localPlayerFinished = false
    }

    // MARK: - Cleanup

    func cleanup() {
        countdownTask?.cancel()
        countdownTask = nil
        progressTimer?.invalidate()
        progressTimer = nil
        raceService.stopObserving()
        raceService.stopMonitoringConnection()
    }

    private func ensureAuthenticated(completion: @escaping (Bool) -> Void) {
        if syncPlayerIdWithAuth() {
            completion(true)
            return
        }
        raceService.authenticateAnonymouslyIfNeeded { [weak self] error in
            Task { @MainActor in
                guard let self else {
                    completion(false)
                    return
                }
                if error != nil {
                    self.actionError = "Couldn't sign in. Check your connection and try again."
                    completion(false)
                    return
                }
                guard self.syncPlayerIdWithAuth() else {
                    self.actionError = "Couldn't sign in. Try again."
                    completion(false)
                    return
                }
                completion(true)
            }
        }
    }

    private func runCountdownAnimation(raceId: String, shouldStartRacing: Bool) {
        countdownTask?.cancel()
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
                if shouldStartRacing {
                    self.raceService.startRacing(raceId: raceId)
                }
            }
        }
    }

    private func syncPlayerIdWithAuth() -> Bool {
        guard let authUID = Auth.auth().currentUser?.uid else { return false }
        if localPlayerId != authUID {
            localPlayerId = authUID
            UserDefaults(suiteName: "group.com.typeracer.shared")?.set(authUID, forKey: "playerId")
        }
        return true
    }

    deinit {
        progressTimer?.invalidate()
    }
}
