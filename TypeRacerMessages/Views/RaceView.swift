import SwiftUI

struct RaceView: View {
    @ObservedObject var gameState: GameState
    @FocusState private var isInputFocused: Bool

    private var sentence: String {
        gameState.race?.sentence ?? ""
    }

    private var localProgress: Double {
        gameState.typedText.typingProgress(against: sentence)
    }

    var body: some View {
        VStack(spacing: 16) {
            if !gameState.isConnected {
                Label("Connection lost. Waiting to reconnect...", systemImage: "wifi.slash")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.yellow.opacity(0.2), in: Capsule())
                    .padding(.top, 8)
            }

            // Timer + WPM header
            HStack {
                Label(formatTime(gameState.elapsedSeconds), systemImage: "timer")
                    .font(.headline.monospacedDigit())
                Spacer()
                Label("\(gameState.wpm) WPM", systemImage: "bolt.fill")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.orange)
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Quote attribution
            if let race = gameState.race {
                Text("— \(race.quoteAuthor), \(race.quoteSource)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal)
            }

            // Target sentence with character highlighting
            SentenceDisplay(sentence: sentence, typedText: gameState.typedText)
                .padding(.horizontal)

            // Progress bars for all players
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    if let players = gameState.race?.sortedPlayers {
                        ForEach(players) { player in
                            PlayerProgressBar(
                                player: player,
                                isLocal: player.id == gameState.localPlayerId
                            )
                        }
                    }
                }
                .padding(.horizontal)
            }

            Spacer()

            // Typing input
            TextField("Start typing...", text: Binding(
                get: { gameState.typedText },
                set: { gameState.onTypingChanged($0) }
            ))
            .textFieldStyle(.roundedBorder)
            .font(.body.monospaced())
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .keyboardType(.asciiCapable)
            .focused($isInputFocused)
            .padding(.horizontal)
            .padding(.bottom, 16)
            .onAppear { isInputFocused = true }
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        let tenths = Int((seconds - Double(Int(seconds))) * 10)
        return String(format: "%d:%02d.%d", mins, secs, tenths)
    }
}

// MARK: - Player Progress Bar

struct PlayerProgressBar: View {
    let player: Player
    let isLocal: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(player.nickname)
                    .font(.caption.bold())
                    .foregroundStyle(isLocal ? .blue : .primary)
                Spacer()
                Text("\(player.wpm) WPM")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isLocal ? Color.blue : Color.green)
                        .frame(width: geo.size.width * player.progress)
                        .animation(.easeOut(duration: 0.2), value: player.progress)
                }
            }
            .frame(height: 8)

            if player.hasFinished {
                Text("Finished!")
                    .font(.caption2)
                    .foregroundStyle(.green)
            }
        }
        .frame(width: 150)
    }
}
