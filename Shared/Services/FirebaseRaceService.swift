import Foundation
import FirebaseDatabase

private enum RaceServiceError: Error {
    case invalidRaceSnapshot
}

final class RaceService: ObservableObject {
    static let shared = RaceService()

    private lazy var db = Database.database().reference()
    private var raceRef: DatabaseReference?
    private var raceHandle: DatabaseHandle?

    @Published var currentRace: Race?
    @Published var isConnected: Bool = true

    private var connectedRef: DatabaseReference?
    private var connectedHandle: DatabaseHandle?

    private init() {
        startMonitoringConnection()
    }

    // MARK: - Connection Monitoring

    private func startMonitoringConnection() {
        connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedHandle = connectedRef?.observe(.value) { [weak self] snapshot in
            let connected = snapshot.value as? Bool ?? false
            DispatchQueue.main.async {
                self?.isConnected = connected
            }
            if connected {
                print("[TypeRacer] Firebase connected")
            } else {
                print("[TypeRacer] Firebase disconnected")
            }
        }
    }

    // MARK: - Race Lifecycle

    func createRace(sentence: String, quoteAuthor: String, quoteSource: String, creator: Player) -> Race {
        let raceId = UUID().uuidString
        var race = Race(
            id: raceId,
            sentence: sentence,
            quoteAuthor: quoteAuthor,
            quoteSource: quoteSource
        )
        var creatorPlayer = creator
        creatorPlayer.isCreator = true
        race.players[creator.id] = creatorPlayer

        if let dict = race.asFirebaseDict() {
            db.child("races").child(raceId).setValue(dict)
        }
        return race
    }

    func joinRace(raceId: String, player: Player) {
        if let dict = player.asFirebaseDict() {
            db.child("races").child(raceId).child("players").child(player.id).setValue(dict)
        }
    }

    // MARK: - Status Updates

    func startCountdown(raceId: String) {
        db.child("races").child(raceId).updateChildValues([
            "status": RaceStatus.countdown.rawValue,
            "countdownStartAt": ServerValue.timestamp(),
        ])
    }

    func startRacing(raceId: String) {
        db.child("races").child(raceId).updateChildValues([
            "status": RaceStatus.racing.rawValue,
            "raceStartAt": ServerValue.timestamp(),
        ])
    }

    func finishRace(raceId: String) {
        db.child("races").child(raceId).updateChildValues([
            "status": RaceStatus.finished.rawValue,
        ])
    }

    /// Resets the same race id for a rematch: new quote, `waiting` status, cleared timers and per-player progress.
    func resetRaceForRematch(
        raceId: String,
        sentence: String,
        quoteAuthor: String,
        quoteSource: String
    ) async throws {
        let ref = db.child("races").child(raceId)
        let snapshot = try await ref.getData()
        guard let dict = snapshot.value as? [String: Any],
              let players = dict["players"] as? [String: Any] else {
            throw RaceServiceError.invalidRaceSnapshot
        }

        var updates: [String: Any] = [
            "status": RaceStatus.waiting.rawValue,
            "sentence": sentence,
            "quoteAuthor": quoteAuthor,
            "quoteSource": quoteSource,
            "countdownStartAt": NSNull(),
            "raceStartAt": NSNull(),
        ]
        for playerId in players.keys {
            updates["players/\(playerId)/progress"] = 0
            updates["players/\(playerId)/wpm"] = 0
            updates["players/\(playerId)/finishedAt"] = NSNull()
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ref.updateChildValues(updates) { error, _ in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    // MARK: - Player Progress

    func updateProgress(raceId: String, playerId: String, progress: Double, wpm: Int) {
        db.child("races").child(raceId).child("players").child(playerId).updateChildValues([
            "progress": progress,
            "wpm": wpm,
        ])
    }

    func markPlayerFinished(raceId: String, playerId: String, wpm: Int) {
        db.child("races").child(raceId).child("players").child(playerId).updateChildValues([
            "progress": 1.0,
            "wpm": wpm,
            "finishedAt": ServerValue.timestamp(),
        ])
    }

    // MARK: - Observe

    func observeRace(raceId: String, onChange: @escaping (Race?) -> Void) {
        stopObserving()
        raceRef = db.child("races").child(raceId)
        raceHandle = raceRef?.observe(.value) { snapshot in
            guard let dict = snapshot.value as? [String: Any],
                  let data = try? JSONSerialization.data(withJSONObject: dict),
                  let race = try? JSONDecoder().decode(Race.self, from: data) else {
                onChange(nil)
                return
            }
            DispatchQueue.main.async {
                self.currentRace = race
                onChange(race)
            }
        }
    }

    func stopObserving() {
        if let handle = raceHandle {
            raceRef?.removeObserver(withHandle: handle)
        }
        raceHandle = nil
        raceRef = nil
    }

    func stopMonitoringConnection() {
        if let handle = connectedHandle {
            connectedRef?.removeObserver(withHandle: handle)
        }
        connectedHandle = nil
        connectedRef = nil
    }

    // MARK: - Fetch Once

    func fetchRace(raceId: String) async -> Race? {
        do {
            let snapshot = try await db.child("races").child(raceId).getData()
            guard let dict = snapshot.value as? [String: Any],
                  let data = try? JSONSerialization.data(withJSONObject: dict),
                  let race = try? JSONDecoder().decode(Race.self, from: data) else {
                return nil
            }
            return race
        } catch {
            return nil
        }
    }
}

// MARK: - Firebase Encoding Helpers

private extension Encodable {
    func asFirebaseDict() -> [String: Any]? {
        guard let data = try? JSONEncoder().encode(self),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return dict
    }
}
