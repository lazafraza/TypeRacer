import Foundation

struct MessageURLCoder {
    private static let baseURL = "https://typeracer.app"

    static func encode(raceId: String, status: RaceStatus = .waiting, winnerName: String? = nil, winnerWPM: Int? = nil) -> URL {
        var components = URLComponents(string: baseURL)!
        var items = [
            URLQueryItem(name: "raceId", value: raceId),
            URLQueryItem(name: "status", value: status.rawValue),
        ]
        if let winnerName {
            items.append(URLQueryItem(name: "winner", value: winnerName))
        }
        if let winnerWPM {
            items.append(URLQueryItem(name: "wpm", value: String(winnerWPM)))
        }
        components.queryItems = items
        return components.url!
    }

    static func decode(url: URL) -> (raceId: String, status: RaceStatus, winnerName: String?, winnerWPM: Int?)? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let items = components.queryItems else { return nil }

        var raceId: String?
        var status: RaceStatus = .waiting
        var winnerName: String?
        var winnerWPM: Int?

        for item in items {
            switch item.name {
            case "raceId": raceId = item.value
            case "status": status = RaceStatus(rawValue: item.value ?? "") ?? .waiting
            case "winner": winnerName = item.value
            case "wpm": winnerWPM = Int(item.value ?? "")
            default: break
            }
        }

        guard let id = raceId else { return nil }
        return (id, status, winnerName, winnerWPM)
    }
}
