import SwiftUI

struct LobbyView: View {
    @ObservedObject var gameState: GameState
    let onStartRace: () -> Void

    private var isCreator: Bool {
        guard let race = gameState.race else { return false }
        return race.players[gameState.localPlayerId]?.isCreator == true
    }

    private var canStart: Bool {
        (gameState.race?.playerCount ?? 0) >= 2
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 4) {
                Text("Type Race")
                    .font(.largeTitle.bold())
                Text("Waiting for players...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 20)

            // Nickname editor
            HStack {
                Text("Your name:")
                    .foregroundStyle(.secondary)
                TextField("Nickname", text: Binding(
                    get: { gameState.localNickname },
                    set: { gameState.saveNickname($0) }
                ))
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 200)
            }
            .padding(.horizontal)

            // Player list
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Players (\(gameState.race?.playerCount ?? 0))")
                        .font(.headline)
                    Spacer()
                    if !gameState.isConnected {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Text("Offline")
                                .font(.caption.bold())
                                .foregroundStyle(.red)
                        }
                    }
                }

                if let players = gameState.race?.sortedPlayers {
                    ForEach(players) { player in
                        HStack {
                            Image(systemName: player.isCreator ? "crown.fill" : "person.fill")
                                .foregroundStyle(player.isCreator ? .yellow : .blue)
                            Text(player.nickname)
                                .font(.body)
                            if player.id == gameState.localPlayerId {
                                Text("(you)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)

            Spacer()

            // Start button (any player, 2+ players)
            Button(action: onStartRace) {
                Text(canStart ? "Start Race" : "Waiting for players...")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canStart ? Color.green : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!canStart)
            .padding(.horizontal)

            // Tap send reminder
            Text("Tap Send to share this race with your group!")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 16)
        }
    }
}
