import SwiftUI

struct ResultsView: View {
    @ObservedObject var gameState: GameState
    let onShareResults: () -> Void
    let onRematch: () -> Void

    private var canRematch: Bool {
        (gameState.race?.playerCount ?? 0) >= 2
    }

    private var rankedPlayers: [Player] {
        guard let race = gameState.race else { return [] }
        return race.players.values.sorted { a, b in
            // Finished players first, sorted by finishedAt
            switch (a.finishedAt, b.finishedAt) {
            case let (aTime?, bTime?):
                return aTime < bTime
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            default:
                return a.progress > b.progress
            }
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            // Winner announcement
            if let winner = gameState.race?.winner {
                VStack(spacing: 8) {
                    Text("Winner!")
                        .font(.title2.bold())
                        .foregroundStyle(.yellow)
                    Text(winner.nickname)
                        .font(.largeTitle.bold())
                    Text("\(winner.wpm) WPM")
                        .font(.title3.monospacedDigit())
                        .foregroundStyle(.orange)
                }
                .padding(.top, 24)
            } else {
                Text("Race Complete")
                    .font(.title.bold())
                    .padding(.top, 24)
            }

            // Quote info
            if let race = gameState.race {
                VStack(spacing: 2) {
                    Text("\"\(race.sentence)\"")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    Text("— \(race.quoteAuthor)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal)
            }

            // Rankings
            VStack(spacing: 0) {
                ForEach(Array(rankedPlayers.enumerated()), id: \.element.id) { index, player in
                    HStack {
                        // Rank
                        Text(rankEmoji(index))
                            .font(.title2)
                            .frame(width: 40)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(player.nickname)
                                    .font(.headline)
                                if player.id == gameState.localPlayerId {
                                    Text("(you)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            if player.hasFinished {
                                Text("\(player.wpm) WPM")
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(.orange)
                            } else {
                                Text("Did not finish (\(Int(player.progress * 100))%)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal)

                    if index < rankedPlayers.count - 1 {
                        Divider().padding(.leading, 56)
                    }
                }
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)

            Spacer()

            if canRematch {
                Button(action: onRematch) {
                    Text("Rematch")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            }

            // Share results button
            Button(action: onShareResults) {
                Text("Share Results")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
    }

    private func rankEmoji(_ index: Int) -> String {
        switch index {
        case 0: return "1st"
        case 1: return "2nd"
        case 2: return "3rd"
        default: return "\(index + 1)th"
        }
    }
}
