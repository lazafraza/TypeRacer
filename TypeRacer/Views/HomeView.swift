import SwiftUI

struct HomeView: View {
    @State private var showPractice = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Logo area
                VStack(spacing: 8) {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)
                    Text("TypeRacer")
                        .font(.largeTitle.bold())
                    Text("Race your friends in iMessage")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Actions
                VStack(spacing: 16) {
                    NavigationLink(destination: PracticeView()) {
                        Label("Practice Mode", systemImage: "figure.run")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    NavigationLink(destination: HowToPlayView()) {
                        Label("How to Play", systemImage: "questionmark.circle")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Practice Mode

struct PracticeView: View {
    @State private var quote: Quote = QuoteService.shared.randomQuote(difficulty: .medium)
    @State private var typedText = ""
    @State private var startTime: Date?
    @State private var elapsedSeconds: TimeInterval = 0
    @State private var wpm: Int = 0
    @State private var isFinished = false
    @State private var timer: Timer?
    @FocusState private var isInputFocused: Bool
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 16) {
            // Timer + WPM
            HStack {
                Label(formatTime(elapsedSeconds), systemImage: "timer")
                    .font(.headline.monospacedDigit())
                Spacer()
                Label("\(wpm) WPM", systemImage: "bolt.fill")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.orange)
            }
            .padding(.horizontal)

            // Attribution
            Text("— \(quote.author), \(quote.source)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal)

            // Sentence
            SentenceDisplay(sentence: quote.text, typedText: typedText)
                .padding(.horizontal)

            Spacer()

            if isFinished {
                VStack(spacing: 12) {
                    Text("Done!")
                        .font(.title.bold())
                    Text("\(wpm) WPM")
                        .font(.title2.monospacedDigit())
                        .foregroundStyle(.orange)
                    Button("New Quote") {
                        resetPractice()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                TextField("Start typing...", text: $typedText)
                    .textFieldStyle(.roundedBorder)
                    .font(.body.monospaced())
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.asciiCapable)
                    .focused($isInputFocused)
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    .onChange(of: typedText) { _, newValue in
                        onTypingChanged(newValue)
                    }
                    .onAppear { isInputFocused = true }
            }
        }
        .navigationTitle("Practice")
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active {
                timer?.invalidate()
                timer = nil
            }
        }
    }

    private func onTypingChanged(_ text: String) {
        // Start timer on first keystroke
        if startTime == nil && !text.isEmpty {
            startTime = Date()
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                guard let start = startTime else { return }
                elapsedSeconds = Date().timeIntervalSince(start)
            }
        }

        let correctChars = text.correctCharacterCount(against: quote.text)
        wpm = String.wpm(correctChars: correctChars, elapsedSeconds: elapsedSeconds)

        if text.typingProgress(against: quote.text) >= 1.0 {
            timer?.invalidate()
            timer = nil
            isFinished = true
        }
    }

    private func resetPractice() {
        timer?.invalidate()
        timer = nil
        quote = QuoteService.shared.randomQuote(difficulty: .medium)
        typedText = ""
        startTime = nil
        elapsedSeconds = 0
        wpm = 0
        isFinished = false
        isInputFocused = true
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        let tenths = Int((seconds - Double(Int(seconds))) * 10)
        return String(format: "%d:%02d.%d", mins, secs, tenths)
    }
}

// MARK: - How to Play

struct HowToPlayView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                step(number: 1, title: "Open iMessage",
                     description: "Go to a group chat and tap the Apps bar. Find TypeRacer in your iMessage apps.")

                step(number: 2, title: "Start a Race",
                     description: "Tap \"Start a Type Race!\" to create a new race. A message will appear in your chat — tap Send to share it.")

                step(number: 3, title: "Friends Join",
                     description: "Your friends tap the message bubble to join the race lobby. You'll see everyone who's joined.")

                step(number: 4, title: "Race!",
                     description: "The host taps Start. After a 3-2-1 countdown, everyone types the same sentence as fast as they can. You'll see live progress bars for all racers.")

                step(number: 5, title: "Win",
                     description: "First to type the full sentence correctly wins! Results are shared back to the group chat.")
            }
            .padding(24)
        }
        .navigationTitle("How to Play")
    }

    private func step(number: Int, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text("\(number)")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Color.blue, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
